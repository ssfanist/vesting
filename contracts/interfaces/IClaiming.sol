// SPDX-License-Identifier: MIT

pragma solidity ^0.7.4;

interface IClaiming {
    event PoolAdded(
        uint256 indexed pid,
        string _name,
        address _purchaseToken,
        address _claimToken,
        uint256 _allocSize,
        uint256 _price,
        bytes32 _whitelistRoot,
        address _beneficiary
    );
    event Claimed(address indexed user, uint256 amount);
    event FundWithdrawed(address indexed beneficiary, uint256 amount);
    event Deposited(uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed token, address beneficiary, uint256 amount);

    function initialize(address _owner) external;

    function pause() external;

    function unpause() external;

    function claim(
        uint256 _pid,
        uint256 _amount,
        bytes32[] calldata _whitelistProof
    ) external;
}
