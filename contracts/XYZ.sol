//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract XYZ is ERC20 {
    constructor() ERC20("XYZ Token", "XYZ") {
        _mint(msg.sender, 10_000_000 ether);
    }
}
