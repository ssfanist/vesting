// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract VestingMock is ERC20 {
    constructor() ERC20("Vesting Mock", "Vest") {}

    function mintArbitrary(address _to, uint256 _amount) public {
        _mint(_to, _amount);
    }
}
