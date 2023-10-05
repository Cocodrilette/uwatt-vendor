// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ERC20UWATT is ERC20 {
    constructor() ERC20("ERC20UWATT", "ERC20UWATT") {}

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }
}
