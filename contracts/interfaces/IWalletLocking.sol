// SPDX-License-Identifier: MIT

pragma solidity ^0.7.4;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
interface IWalletLocking {

	struct DepositInfo {
		address _token;
		uint256 lock;
		uint256[] _percentages;
		uint256[] vestings;
		uint256 depositTime;
		uint256 totalAmount;
	}

	event Lock(uint256 indexed depositId, address _token ,uint256 _lock, uint256[] _vesting, uint256[] _percentages, address[] _beneficiaries, uint256[] _allocAmounts);
	event Withdraw(uint256 indexed depositId, uint256 amount, address _beneficiary);

	function lock(address _token, uint256 _lock, uint256[] memory _percentages, uint256[] memory _vestings, address[] memory _beneficiaries, uint256[] memory _allocAmounts) external;
	function withdraw(uint256 depositId) external;
}
