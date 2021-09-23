// SPDX-License-Identifier: MIT

pragma solidity ^0.7.4;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
interface ILPLocking {

	struct DepositInfo {
		address lpToken;
		uint256 amount;
		uint256 vesting;
		uint256 lock;
		address beneficiary;
		uint256 depositTime;
		uint256 amountWithdraw;
	}

	event Deposit(uint256 indexed depositId, address _lpToken, uint256 _amount, uint256 _lock, uint256 _vesting, address _beneficiary);
	event UpdateBeneficiary(uint256 indexed depositId, address _beneficiary);
	event Withdraw(uint256 indexed depositId, uint256 amount, address _beneficiary);

	function deposit(address _lpToken, uint256 _amount, uint256 _lock, uint256 _vesting, address _beneficiary) external;
	function updateBeneficiary(uint256 _depositId, address _beneficiary) external;
	function withdraw(uint256 depositId) external;
}
