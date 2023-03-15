// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.8.0;

interface IAddressRegistry {
    function register(uint256 _cidNFTID) external;

    function remove() external;

    function removeOnTransfer(address _transferFrom, uint256 _cidNFTID) external;

    function getCID(address _user) external view returns (uint256 cidNFTID);

    function getAddress(uint256 _cidNFTID) external view returns (address user);
}
