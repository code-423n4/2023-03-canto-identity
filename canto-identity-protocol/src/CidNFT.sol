// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.8.0;

import {ERC721} from "solmate/tokens/ERC721.sol";
import "solmate/tokens/ERC20.sol";
import "solmate/utils/SafeTransferLib.sol";
import "solmate/auth/Owned.sol";
import "./SubprotocolRegistry.sol";
import "./AddressRegistry.sol";
import "../interface/Turnstile.sol";

/// @title Canto Identity Protocol NFT
/// @notice CID NFTs are at the heart of the CID protocol. All key/values of subprotocols are associated with them.
contract CidNFT is ERC721, Owned {
    /*//////////////////////////////////////////////////////////////
                                 CONSTANTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Fee (in BPS) that is charged for every add call (as a percentage of the subprotocol fee). Fixed at 10%.
    uint256 public constant CID_FEE_BPS = 1_000;

    /*//////////////////////////////////////////////////////////////
                                 ADDRESSES
    //////////////////////////////////////////////////////////////*/

    /// @notice Wallet that receives CID fees
    address public immutable cidFeeWallet;

    /// @notice Reference to the NOTE TOKEN
    ERC20 public immutable note;

    /// @notice Reference to the subprotocol registry
    SubprotocolRegistry public immutable subprotocolRegistry;

    /// @notice Reference to the address registry. Must be set by the owner
    AddressRegistry public addressRegistry;

    /*//////////////////////////////////////////////////////////////
                                 STATE
    //////////////////////////////////////////////////////////////*/

    /// @notice Base URI of the NFT
    string public baseURI;

    /// @notice Array of uint256 values (NFT IDs) with additional position information NFT ID => (array pos. + 1)
    struct IndexedArray {
        uint256[] values;
        mapping(uint256 => uint256) positions;
    }

    /// @notice Data that is associated with a CID NFT -> subprotocol name combination
    struct SubprotocolData {
        /// @notice Mapping (key => subprotocol NFT ID) for ordered type
        mapping(uint256 => uint256) ordered;
        /// @notice Value (subprotocol NFT ID) for primary type
        uint256 primary;
        /// @notice List (of subprotocol NFT IDs) for active type
        IndexedArray active;
    }

    /// @notice The different types of associations between CID NFTs and subprotocol NFTs
    enum AssociationType {
        /// @notice key => NFT mapping
        ORDERED,
        /// @notice Zero or one NFT
        PRIMARY,
        /// @notice List of NFTs
        ACTIVE
    }

    /// @notice Data that is associated with a subprotocol name -> subprotocol NFT ID combination (for reverse lookups)
    struct CIDNFTSubprotocolData {
        /// @notice Referenced CID NFT ID
        uint256 cidNFTID;
        /// @notice Key (for ordered) or array position (for active)
        uint256 position;
    }

    /// @notice Counter of the minted NFTs
    /// @dev Used to assign a new unique ID. The first ID that is assigned is 1, ID 0 is never minted.
    uint256 public numMinted;

    /// @notice Stores the references to subprotocol NFTs. Mapping nftID => subprotocol name => subprotocol data
    mapping(uint256 => mapping(string => SubprotocolData)) internal cidData;

    /// @notice Allows lookups of subprotocol NFTs to CID NFTs. Mapping subprotocol name => subprotocol NFT ID => AssociationType => (CID NFT ID, position or key)
    mapping(string => mapping(uint256 => mapping(AssociationType => CIDNFTSubprotocolData))) internal cidDataInverse;

    /// @notice Data that is passed to mint to directly add associations to the minted CID NFT
    struct MintAddData {
        string subprotocolName;
        uint256 key;
        uint256 nftIDToAdd;
        AssociationType associationType;
    }

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    event OrderedDataAdded(
        uint256 indexed cidNFTID,
        string indexed subprotocolName,
        uint256 indexed key,
        uint256 subprotocolNFTID
    );
    event PrimaryDataAdded(uint256 indexed cidNFTID, string indexed subprotocolName, uint256 subprotocolNFTID);
    event ActiveDataAdded(
        uint256 indexed cidNFTID,
        string indexed subprotocolName,
        uint256 subprotocolNFTID,
        uint256 arrayIndex
    );
    event OrderedDataRemoved(
        uint256 indexed cidNFTID,
        string indexed subprotocolName,
        uint256 indexed key,
        uint256 subprotocolNFTID
    );
    event PrimaryDataRemoved(uint256 indexed cidNFTID, string indexed subprotocolName, uint256 subprotocolNFTID);
    event ActiveDataRemoved(uint256 indexed cidNFTID, string indexed subprotocolName, uint256 subprotocolNFTID);

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/
    error TokenNotMinted(uint256 tokenID);
    error SubprotocolDoesNotExist(string subprotocolName);
    error NFTIDZeroDisallowedForSubprotocols();
    error AssociationTypeNotSupportedForSubprotocol(AssociationType associationType, string subprotocolName);
    error NotAuthorizedForCIDNFT(address caller, uint256 cidNFTID, address cidNFTOwner);
    error NotAuthorizedForSubprotocolNFT(address caller, uint256 subprotocolNFTID);
    error ActiveArrayAlreadyContainsID(uint256 cidNFTID, string subprotocolName, uint256 nftIDToAdd);
    error OrderedValueNotSet(uint256 cidNFTID, string subprotocolName, uint256 key);
    error PrimaryValueNotSet(uint256 cidNFTID, string subprotocolName);
    error ActiveArrayDoesNotContainID(uint256 cidNFTID, string subprotocolName, uint256 nftIDToRemove);

    /// @notice Sets the name, symbol, baseURI, and the address of the auction factory
    /// @param _name Name of the NFT
    /// @param _symbol Symbol of the NFT
    /// @param _baseURI NFT base URI. {id}.json is appended to this URI
    /// @param _cidFeeWallet Address of the wallet that receives the fees
    /// @param _noteContract Address of the $NOTE contract
    /// @param _subprotocolRegistry Address of the subprotocol registry
    constructor(
        string memory _name,
        string memory _symbol,
        string memory _baseURI,
        address _cidFeeWallet,
        address _noteContract,
        address _subprotocolRegistry
    ) ERC721(_name, _symbol) Owned(msg.sender) {
        baseURI = _baseURI;
        cidFeeWallet = _cidFeeWallet;
        note = ERC20(_noteContract);
        subprotocolRegistry = SubprotocolRegistry(_subprotocolRegistry);
        if (block.chainid == 7700) {
            // Register CSR on Canto mainnnet
            Turnstile turnstile = Turnstile(0xEcf044C5B4b867CFda001101c617eCd347095B44);
            turnstile.register(tx.origin);
        }
    }

    /// @notice Get the token URI for the provided ID
    /// @param _id ID to retrieve the URI for
    /// @return tokenURI The URI of the queried token (path to a JSON file)
    function tokenURI(uint256 _id) public view override returns (string memory) {
        if (_ownerOf[_id] == address(0))
            // According to ERC721, this revert for non-existing tokens is required
            revert TokenNotMinted(_id);
        return baseURI;
    }

    /// @notice Mint a new CID NFT
    /// @dev An address can mint multiple CID NFTs, but it can only set one as associated with it in the AddressRegistry
    /// @param _addList An optional list of parameters for add to add subprotocol NFTs directly after minting.
    function mint(MintAddData[] calldata _addList) external {
        uint256 tokenToMint = ++numMinted;
        _mint(msg.sender, tokenToMint); // We do not use _safeMint here on purpose. If a contract calls this method, he expects to get an NFT back
        for (uint256 i = 0; i < _addList.length; ++i) {
            MintAddData calldata addData = _addList[i];
            add(tokenToMint, addData.subprotocolName, addData.key, addData.nftIDToAdd, addData.associationType);
        }
    }

    /// @notice Add a new entry for the given subprotocol to the provided CID NFT
    /// @param _cidNFTID ID of the CID NFT to add the data to
    /// @param _subprotocolName Name of the subprotocol where the data will be added. Has to exist.
    /// @param _key Key to set. This value is only relevant for the AssociationType ORDERED (where a mapping int => nft ID is stored)
    /// @param _nftIDToAdd The ID of the NFT to add
    /// @param _type Association type (see AssociationType struct) to use for this data
    function add(
        uint256 _cidNFTID,
        string calldata _subprotocolName,
        uint256 _key,
        uint256 _nftIDToAdd,
        AssociationType _type
    ) public {
        SubprotocolRegistry.SubprotocolData memory subprotocolData = subprotocolRegistry.getSubprotocol(
            _subprotocolName
        );
        address subprotocolOwner = subprotocolData.owner;
        if (subprotocolOwner == address(0)) revert SubprotocolDoesNotExist(_subprotocolName);
        address cidNFTOwner = _ownerOf[_cidNFTID];
        if (
            cidNFTOwner != msg.sender &&
            getApproved[_cidNFTID] != msg.sender &&
            !isApprovedForAll[cidNFTOwner][msg.sender]
        ) revert NotAuthorizedForCIDNFT(msg.sender, _cidNFTID, cidNFTOwner);
        if (_nftIDToAdd == 0) revert NFTIDZeroDisallowedForSubprotocols(); // ID 0 is disallowed in subprotocols

        // The CID Protocol safeguards the NFTs of subprotocols. Note that these NFTs are usually pointers to other data / NFTs (e.g., to an image NFT for profile pictures)
        ERC721 nftToAdd = ERC721(subprotocolData.nftAddress);
        nftToAdd.transferFrom(msg.sender, address(this), _nftIDToAdd);
        // Charge fee (subprotocol & CID fee) if configured
        uint96 subprotocolFee = subprotocolData.fee;
        if (subprotocolFee != 0) {
            uint256 cidFee = (subprotocolFee * CID_FEE_BPS) / 10_000;
            SafeTransferLib.safeTransferFrom(note, msg.sender, cidFeeWallet, cidFee);
            SafeTransferLib.safeTransferFrom(note, msg.sender, subprotocolOwner, subprotocolFee - cidFee);
        }
        if (_type == AssociationType.ORDERED) {
            if (!subprotocolData.ordered) revert AssociationTypeNotSupportedForSubprotocol(_type, _subprotocolName);
            if (cidData[_cidNFTID][_subprotocolName].ordered[_key] != 0) {
                // Remove to ensure that user gets NFT back
                remove(_cidNFTID, _subprotocolName, _key, 0, _type);
            }
            cidData[_cidNFTID][_subprotocolName].ordered[_key] = _nftIDToAdd;
            cidDataInverse[_subprotocolName][_nftIDToAdd][AssociationType.ORDERED] = CIDNFTSubprotocolData(
                _cidNFTID,
                _key
            );
            emit OrderedDataAdded(_cidNFTID, _subprotocolName, _key, _nftIDToAdd);
        } else if (_type == AssociationType.PRIMARY) {
            if (!subprotocolData.primary) revert AssociationTypeNotSupportedForSubprotocol(_type, _subprotocolName);
            if (cidData[_cidNFTID][_subprotocolName].primary != 0) {
                // Remove to ensure that user gets NFT back
                remove(_cidNFTID, _subprotocolName, 0, 0, _type);
            }
            cidData[_cidNFTID][_subprotocolName].primary = _nftIDToAdd;
            cidDataInverse[_subprotocolName][_nftIDToAdd][AssociationType.PRIMARY] = CIDNFTSubprotocolData(
                _cidNFTID,
                0
            );
            emit PrimaryDataAdded(_cidNFTID, _subprotocolName, _nftIDToAdd);
        } else if (_type == AssociationType.ACTIVE) {
            if (!subprotocolData.active) revert AssociationTypeNotSupportedForSubprotocol(_type, _subprotocolName);
            IndexedArray storage activeData = cidData[_cidNFTID][_subprotocolName].active;
            uint256 lengthBeforeAddition = activeData.values.length;
            if (lengthBeforeAddition == 0) {
                uint256[] memory nftIDsToAdd = new uint256[](1);
                nftIDsToAdd[0] = _nftIDToAdd;
                activeData.values = nftIDsToAdd;
                activeData.positions[_nftIDToAdd] = 1; // Array index + 1
            } else {
                // Check for duplicates
                if (activeData.positions[_nftIDToAdd] != 0)
                    revert ActiveArrayAlreadyContainsID(_cidNFTID, _subprotocolName, _nftIDToAdd);
                activeData.values.push(_nftIDToAdd);
                activeData.positions[_nftIDToAdd] = lengthBeforeAddition + 1;
            }
            cidDataInverse[_subprotocolName][_nftIDToAdd][AssociationType.ACTIVE] = CIDNFTSubprotocolData(
                _cidNFTID,
                lengthBeforeAddition
            );
            emit ActiveDataAdded(_cidNFTID, _subprotocolName, _nftIDToAdd, lengthBeforeAddition);
        }
    }

    /// @notice Remove / unset a key for the given CID NFT and subprotocol
    /// @param _cidNFTID ID of the CID NFT to remove the data from
    /// @param _subprotocolName Name of the subprotocol where the data will be removed. Has to exist.
    /// @param _key Key to unset. This value is only relevant for the AssociationType ORDERED
    /// @param _nftIDToRemove The ID of the NFT to remove. Only needed for the AssociationType ACTIVE
    /// @param _type Association type (see AssociationType struct) to remove this data from
    function remove(
        uint256 _cidNFTID,
        string calldata _subprotocolName,
        uint256 _key,
        uint256 _nftIDToRemove,
        AssociationType _type
    ) public {
        SubprotocolRegistry.SubprotocolData memory subprotocolData = subprotocolRegistry.getSubprotocol(
            _subprotocolName
        );
        address subprotocolOwner = subprotocolData.owner;
        if (subprotocolOwner == address(0)) revert SubprotocolDoesNotExist(_subprotocolName);
        address cidNFTOwner = _ownerOf[_cidNFTID];
        if (
            cidNFTOwner != msg.sender &&
            getApproved[_cidNFTID] != msg.sender &&
            !isApprovedForAll[cidNFTOwner][msg.sender]
        ) revert NotAuthorizedForCIDNFT(msg.sender, _cidNFTID, cidNFTOwner);

        ERC721 nftToRemove = ERC721(subprotocolData.nftAddress);
        if (_type == AssociationType.ORDERED) {
            // We do not have to check if ordered is supported by the subprotocol. If not, the value will not be unset (which is checked below)
            uint256 currNFTID = cidData[_cidNFTID][_subprotocolName].ordered[_key];
            if (currNFTID == 0)
                // This check is technically not necessary (because the NFT transfer would fail), but we include it to have more meaningful errors
                revert OrderedValueNotSet(_cidNFTID, _subprotocolName, _key);
            delete cidData[_cidNFTID][_subprotocolName].ordered[_key];
            delete cidDataInverse[_subprotocolName][currNFTID][AssociationType.ORDERED];
            nftToRemove.transferFrom(address(this), msg.sender, currNFTID); // Use transferFrom here to prevent reentrancy possibility when remove is called from add
            emit OrderedDataRemoved(_cidNFTID, _subprotocolName, _key, currNFTID);
        } else if (_type == AssociationType.PRIMARY) {
            uint256 currNFTID = cidData[_cidNFTID][_subprotocolName].primary;
            if (currNFTID == 0) revert PrimaryValueNotSet(_cidNFTID, _subprotocolName);
            delete cidData[_cidNFTID][_subprotocolName].primary;
            delete cidDataInverse[_subprotocolName][currNFTID][AssociationType.PRIMARY];
            nftToRemove.transferFrom(address(this), msg.sender, currNFTID);
            emit PrimaryDataRemoved(_cidNFTID, _subprotocolName, currNFTID);
        } else if (_type == AssociationType.ACTIVE) {
            IndexedArray storage activeData = cidData[_cidNFTID][_subprotocolName].active;
            uint256 arrayPosition = activeData.positions[_nftIDToRemove]; // Index + 1, 0 if non-existant
            if (arrayPosition == 0) revert ActiveArrayDoesNotContainID(_cidNFTID, _subprotocolName, _nftIDToRemove);
            uint256 arrayLength = activeData.values.length;
            // Swap only necessary if not already the last element
            if (arrayPosition != arrayLength) {
                uint256 befSwapLastNFTID = activeData.values[arrayLength - 1];
                activeData.values[arrayPosition - 1] = befSwapLastNFTID;
                activeData.positions[befSwapLastNFTID] = arrayPosition;
                cidDataInverse[_subprotocolName][befSwapLastNFTID][AssociationType.ACTIVE].position = arrayPosition - 1;
            }
            activeData.values.pop();
            activeData.positions[_nftIDToRemove] = 0;
            nftToRemove.transferFrom(address(this), msg.sender, _nftIDToRemove);
            delete cidDataInverse[_subprotocolName][_nftIDToRemove][AssociationType.ACTIVE];
            emit ActiveDataRemoved(_cidNFTID, _subprotocolName, _nftIDToRemove);
        }
    }

    /// @notice Get the ordered data that is associated with a CID NFT / Subprotocol
    /// @param _cidNFTID ID of the CID NFT to query
    /// @param _subprotocolName Name of the subprotocol to query
    /// @param _key Key to query
    /// @return subprotocolNFTID The ID of the NFT at the queried key. 0 if it does not exist
    function getOrderedData(
        uint256 _cidNFTID,
        string calldata _subprotocolName,
        uint256 _key
    ) external view returns (uint256 subprotocolNFTID) {
        subprotocolNFTID = cidData[_cidNFTID][_subprotocolName].ordered[_key];
    }

    /// @notice Perform an inverse lookup for ordered associations. Given the subprotocol name and subprotocol NFT ID, return the CID NFT ID and the key
    /// @dev cidNFTID is 0 if no association exists
    /// @param _subprotocolName Subprotocl name to query
    /// @param _subprotocolNFTID Subprotocol NFT ID to query
    /// @return key The key with which _subprotocolNFTID is associated, cidNFTID The CID NFT with which the subprotocol NFT ID is associated (0 if none)
    function getOrderedCIDNFT(string calldata _subprotocolName, uint256 _subprotocolNFTID)
        external
        view
        returns (uint256 key, uint256 cidNFTID)
    {
        CIDNFTSubprotocolData storage inverseData = cidDataInverse[_subprotocolName][_subprotocolNFTID][
            AssociationType.ORDERED
        ];
        key = inverseData.position;
        cidNFTID = inverseData.cidNFTID;
    }

    /// @notice Get the primary data that is associated with a CID NFT / Subprotocol
    /// @param _cidNFTID ID of the CID NFT to query
    /// @param _subprotocolName Name of the subprotocol to query
    /// @return subprotocolNFTID The ID of the primary NFT at the queried subprotocl / CID NFT. 0 if it does not exist
    function getPrimaryData(uint256 _cidNFTID, string calldata _subprotocolName)
        external
        view
        returns (uint256 subprotocolNFTID)
    {
        subprotocolNFTID = cidData[_cidNFTID][_subprotocolName].primary;
    }

    /// @notice Perform an inverse lookup for primary associations. Given the subprotocol name and subprotocol NFT ID, return the CID NFT ID
    /// @dev cidNFTID is 0 if no association exists
    /// @param _subprotocolName Subprotocl name to query
    /// @param _subprotocolNFTID Subprotocol NFT ID to query
    /// @return cidNFTID The CID NFT with which the subprotocol NFT ID is associated (0 if none)
    function getPrimaryCIDNFT(string calldata _subprotocolName, uint256 _subprotocolNFTID)
        external
        view
        returns (uint256 cidNFTID)
    {
        CIDNFTSubprotocolData storage inverseData = cidDataInverse[_subprotocolName][_subprotocolNFTID][
            AssociationType.PRIMARY
        ];
        cidNFTID = inverseData.cidNFTID;
    }

    /// @notice Get the active data list that is associated with a CID NFT / Subprotocol
    /// @param _cidNFTID ID of the CID NFT to query
    /// @param _subprotocolName Name of the subprotocol to query
    /// @return subprotocolNFTIDs The ID of the primary NFT at the queried subprotocl / CID NFT. 0 if it does not exist
    function getActiveData(uint256 _cidNFTID, string calldata _subprotocolName)
        external
        view
        returns (uint256[] memory subprotocolNFTIDs)
    {
        subprotocolNFTIDs = cidData[_cidNFTID][_subprotocolName].active.values;
    }

    /// @notice Check if a provided NFT ID is included in the active data list that is associated with a CID NFT / Subprotocol
    /// @param _cidNFTID ID of the CID NFT to query
    /// @param _subprotocolName Name of the subprotocol to query
    /// @return nftIncluded True if the NFT ID is in the list
    function activeDataIncludesNFT(
        uint256 _cidNFTID,
        string calldata _subprotocolName,
        uint256 _nftIDToCheck
    ) external view returns (bool nftIncluded) {
        nftIncluded = cidData[_cidNFTID][_subprotocolName].active.positions[_nftIDToCheck] != 0;
    }

    /// @notice Perform an inverse lookup for active associations. Given the subprotocol name and subprotocol NFT ID, return the CID NFT ID and the array position
    /// @dev cidNFTID is 0 if no association exists
    /// @param _subprotocolName Subprotocl name to query
    /// @param _subprotocolNFTID Subprotocol NFT ID to query
    /// @return position The current position of _subprotocolNFTID. May change in the future because of swaps, cidNFTID The CID NFT with which the subprotocol NFT ID is associated (0 if none)
    function getActiveCIDNFT(string calldata _subprotocolName, uint256 _subprotocolNFTID)
        external
        view
        returns (uint256 position, uint256 cidNFTID)
    {
        CIDNFTSubprotocolData storage inverseData = cidDataInverse[_subprotocolName][_subprotocolNFTID][
            AssociationType.ACTIVE
        ];
        position = inverseData.position;
        cidNFTID = inverseData.cidNFTID;
    }

    /// @notice Used to set the address registry after deployment (because of circular dependencies)
    /// @param _addressRegistry Address of the address registry
    function setAddressRegistry(address _addressRegistry) external onlyOwner {
        if (address(addressRegistry) == address(0)) {
            addressRegistry = AddressRegistry(_addressRegistry);
        }
    }

    /// @notice Override transferFrom to deregister CID NFT in address registry if registered
    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public override {
        super.transferFrom(from, to, id);
        addressRegistry.removeOnTransfer(from, id);
    }
}
