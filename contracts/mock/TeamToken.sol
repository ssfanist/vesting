// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TeamToken is ERC20 {
    constructor() ERC20("TeamToken Mock", "TeamToken") {}

    function mintArbitrary(address _to, uint256 _amount) public {
        _mint(_to, _amount);
    }
}
