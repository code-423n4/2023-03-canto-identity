// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.8.0;

import {MockAddressRegistry} from "./MockAddressRegistry.sol";

contract MockCidNFT {
    uint256 primaryCIDNFTReturnVal;
    uint256 expectedPfpId;

    MockAddressRegistry public immutable addressRegistry;

    constructor() {
        addressRegistry = MockAddressRegistry(new MockAddressRegistry());
    }

    function mockReturnPrimaryCIDNFT(uint256 returnValue) public {
        primaryCIDNFTReturnVal = returnValue;
    }

    function setExpectedPfpId(uint256 _expectedPfpId) public {
        expectedPfpId = _expectedPfpId;
    }

    function getPrimaryCIDNFT(string memory subprotocolName, uint256 pfpId)
        public
        view
        returns (uint256)
    {
        if (expectedPfpId != 0) assert(expectedPfpId == pfpId);
        assert(
            keccak256(abi.encodePacked(subprotocolName)) ==
                keccak256(abi.encodePacked("SubprotocolName"))
        );
        return primaryCIDNFTReturnVal;
    }
}
