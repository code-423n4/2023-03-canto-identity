// SPDX-License-Identifier: GPL-3.0-only
import {ERC721} from "solmate/tokens/ERC721.sol";

pragma solidity >=0.8.0;

contract SubprotocolNFT is ERC721 {
    constructor() ERC721("MockNFT", "MNFT") {}

    function mint(address to, uint256 tokenId) public {
        _mint(to, tokenId);
    }

    function tokenURI(
        uint256 /*id*/
    ) public pure override returns (string memory) {
        return "";
    }
}
