// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.8.0;

import {ERC721} from "solmate/tokens/ERC721.sol";
import "../interface/Turnstile.sol";
import "../interface/ICidNFT.sol";

contract ProfilePicture is ERC721 {
    /*//////////////////////////////////////////////////////////////
                                 STATE
    //////////////////////////////////////////////////////////////*/

    /// @notice Reference to the CID NFT
    ICidNFT private immutable cidNFT;

    /*//////////////////////////////////////////////////////////////
                                 STATE
    //////////////////////////////////////////////////////////////*/

    /// @notice Data that is stored per PFP
    struct ProfilePictureData {
        /// @notice Reference to the NFT contract
        address nftContract;
        /// @notice Referenced nft ID
        uint256 nftID;
    }

    /// @notice Number of tokens minted
    uint256 public numMinted;

    /// @notice Stores the pfp data per NFT
    mapping(uint256 => ProfilePictureData) private pfp;

    /// @notice Name with which the subprotocol is registered
    string public subprotocolName;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    event PfpAdded(
        address indexed minter,
        uint256 indexed pfpNftID,
        address indexed referencedContract,
        uint256 referencedNftId
    );

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/
    error TokenNotMinted(uint256 tokenID);
    error PFPNoLongerOwnedByOriginalOwner(uint256 tokenID);
    error PFPNotOwnedByCaller(address caller, address nftContract, uint256 nftID);

    /// @notice Initiates CSR on mainnet
    /// @param _cidNFT Address of the CID NFT
    /// @param _subprotocolName Name with which the subprotocol is / will be registered in the registry. Registration will not be performed automatically
    constructor(address _cidNFT, string memory _subprotocolName) ERC721("Profile Picture", "PFP") {
        cidNFT = ICidNFT(_cidNFT);
        subprotocolName = _subprotocolName;
        if (block.chainid == 7700) {
            // Register CSR on Canto mainnnet
            Turnstile turnstile = Turnstile(0xEcf044C5B4b867CFda001101c617eCd347095B44);
            turnstile.register(tx.origin);
        }
    }

    /// @notice Get the token URI for the specified _id
    /// @param _id ID to query for
    /// @dev Reverts if PFP is no longer owned by owner of associated CID NFT
    function tokenURI(uint256 _id) public view override returns (string memory) {
        (address nftContract, uint256 nftID) = getPFP(_id);
        if (nftContract == address(0)) revert PFPNoLongerOwnedByOriginalOwner(_id);
        return ERC721(nftContract).tokenURI(nftID);
    }

    /// @notice Mint a new PFP NFT
    /// @param _nftContract The nft contract address to reference
    /// @param _nftID The nft ID to reference
    function mint(address _nftContract, uint256 _nftID) external {
        uint256 tokenId = ++numMinted;
        if (ERC721(_nftContract).ownerOf(_nftID) != msg.sender)
            revert PFPNotOwnedByCaller(msg.sender, _nftContract, _nftID);
        ProfilePictureData storage pictureData = pfp[tokenId];
        pictureData.nftContract = _nftContract;
        pictureData.nftID = _nftID;
        _mint(msg.sender, tokenId);
        emit PfpAdded(msg.sender, tokenId, _nftContract, _nftID);
    }

    /// @notice Query the referenced profile picture
    /// @dev Checks if the PFP is still owned by the owner of the CID NFT
    /// @param _pfpID Profile picture NFT ID to query
    /// @return nftContract The referenced NFT contract (address(0) if no longer owned), nftID The referenced NFT ID
    function getPFP(uint256 _pfpID) public view returns (address nftContract, uint256 nftID) {
        if (_ownerOf[_pfpID] == address(0)) revert TokenNotMinted(_pfpID);
        ProfilePictureData storage pictureData = pfp[_pfpID];
        nftContract = pictureData.nftContract;
        nftID = pictureData.nftID;
        uint256 cidNFTID = cidNFT.getPrimaryCIDNFT(subprotocolName, _pfpID);
        IAddressRegistry addressRegistry = cidNFT.addressRegistry();
        if (cidNFTID == 0 || addressRegistry.getAddress(cidNFTID) != ERC721(nftContract).ownerOf(nftID)) {
            nftContract = address(0);
            nftID = 0; // Strictly not needed because nftContract has to be always checked, but reset nevertheless to 0
        }
    }
}
