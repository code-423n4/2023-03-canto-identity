// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "solmate/tokens/ERC721.sol";

contract MockNamespace is ERC721 {
    constructor() ERC721("Mock Namespace Tray", "MNT") {}

    function tokenURI(
        uint256 id
    ) public view virtual override returns (string memory) {
        return "";
    }
}
