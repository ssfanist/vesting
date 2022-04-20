// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

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
    event Claimed(uint256 indexed pid, address user, uint256 amount);
    event FundWithdrawed(
        uint256 indexed pid,
        address beneficiary,
        uint256 amount
    );
    event Deposited(uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(
        address indexed token,
        address beneficiary,
        uint256 amount
    );

    function initialize(address _owner) external;

    function pause() external;

    function unpause() external;

    function claim(
        uint256 _pid,
        uint256 _amount,
        bytes32[] calldata _whitelistProof
    ) external;
}
