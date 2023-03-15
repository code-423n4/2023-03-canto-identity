// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.8.0;

import "./IERC721.sol";
import "./IAddressRegistry.sol";

interface ICidNFT is IERC721 {
    enum AssociationType {
        ORDERED,
        PRIMARY,
        ACTIVE
    }
    struct MintAddData {
        string subprotocolName;
        uint256 key;
        uint256 nftIDToAdd;
        AssociationType associationType;
    }

    function addressRegistry() external view returns (IAddressRegistry addressRegistry);

    function numMinted() external view returns (uint256);

    function mint(MintAddData[] calldata _addList) external;

    function add(
        uint256 _cidNFTID,
        string calldata _subprotocolName,
        uint256 _key,
        uint256 _nftIDToAdd,
        AssociationType _type
    ) external;

    function remove(
        uint256 _cidNFTID,
        string calldata _subprotocolName,
        uint256 _key,
        uint256 _nftIDToRemove,
        AssociationType _type
    ) external;

    function getOrderedData(
        uint256 _cidNFTID,
        string calldata _subprotocolName,
        uint256 _key
    ) external view returns (uint256 subprotocolNFTID);

    function getOrderedCIDNFT(string calldata _subprotocolName, uint256 _subprotocolNFTID)
        external
        view
        returns (uint256 key, uint256 cidNFTID);

    function getPrimaryData(uint256 _cidNFTID, string calldata _subprotocolName)
        external
        view
        returns (uint256 subprotocolNFTID);

    function getPrimaryCIDNFT(string calldata _subprotocolName, uint256 _subprotocolNFTID)
        external
        view
        returns (uint256 cidNFTID);

    function getActiveData(uint256 _cidNFTID, string calldata _subprotocolName)
        external
        view
        returns (uint256[] memory subprotocolNFTIDs);

    function activeDataIncludesNFT(
        uint256 _cidNFTID,
        string calldata _subprotocolName,
        uint256 _nftIDToCheck
    ) external view returns (bool nftIncluded);

    function getActiveCIDNFT(string calldata _subprotocolName, uint256 _subprotocolNFTID)
        external
        view
        returns (uint256 position, uint256 cidNFTID);
}
