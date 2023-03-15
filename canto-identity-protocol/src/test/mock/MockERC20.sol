// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "solmate/tokens/ERC20.sol";

contract MockToken is ERC20 {
    constructor() ERC20("MockToken", "MTK", 18) {}

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }
}
