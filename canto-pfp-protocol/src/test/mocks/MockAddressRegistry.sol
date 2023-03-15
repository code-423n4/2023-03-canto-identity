// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.8.0;

contract MockAddressRegistry {
    address returnAddress;
    uint256 expectedCidNFTID;

    function mockReturnAddress(address _returnAddress) public {
        returnAddress = _returnAddress;
    }

    function setExpectedCidNFTID(uint256 _expectedCidNFTID) public {
        expectedCidNFTID = _expectedCidNFTID;
    }

    function getAddress(uint256 cidNFTID) public view returns (address) {
        // ensure pass in correct cidNFTID
        if (expectedCidNFTID != 0) assert(expectedCidNFTID == cidNFTID);
        return returnAddress;
    }
}
