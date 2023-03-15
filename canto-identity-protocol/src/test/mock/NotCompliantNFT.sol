// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.8.0;

import "solmate/tokens/ERC721.sol";

contract NotCompliantNFT is ERC721 {
    constructor() ERC721("MockNFTNoCompliant", "MNFT") {}

    function tokenURI(
        uint256 /*id*/
    ) public pure override returns (string memory) {
        return "";
    }

    function supportsInterface(bytes4 interfaceId) public pure override returns (bool) {
        return false;
    }
}
