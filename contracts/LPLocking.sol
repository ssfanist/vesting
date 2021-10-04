// SPDX-License-Identifier: MIT

pragma solidity ^0.7.4;

import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "./interfaces/ILPLocking.sol";


contract LPLocking is ILPLocking{
	using SafeMathUpgradeable for uint256;
	using SafeERC20 for IERC20;

	uint256 public depositId;
	mapping(uint256 => DepositInfo) public depositInfo;

	function deposit(address _lpToken, uint256 _amount, uint256 _lock, uint256 _vesting, address _beneficiary) external override {

		require(_lpToken != address(0), "deposit: token address can't be 0");
		require(_amount > 0, "deposit: amount must be greater than 0");
		require(_beneficiary != address(0), "deposit: _beneficiary address can't be 0");

		DepositInfo storage _depositInfo = depositInfo[depositId];

		_depositInfo.lpToken = _lpToken;
		_depositInfo.amount = _amount;
		_depositInfo.lock = _lock;
		_depositInfo.vesting = _vesting;
		_depositInfo.beneficiary = _beneficiary;
		_depositInfo.depositTime = block.timestamp;

		IERC20 lpToken = IERC20(_lpToken);
		lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);

		emit Deposit(depositId, _lpToken, _amount, _lock, _vesting, _beneficiary);
		depositId = depositId + 1;
	}

	function withdraw(uint256 _depositId) external override {

		require(_depositId <= depositId, "withdraw: depositId is too large");

		DepositInfo storage _depositInfo = depositInfo[_depositId];
		uint256 timePassed = calcTimePassed(_depositId);

		require(_depositInfo.beneficiary == address(msg.sender), "withdraw: not a beneficiary");
		uint256 amount;
		if (timePassed >= _depositInfo.vesting) {
			amount = _depositInfo.amount - _depositInfo.amountWithdraw;
		} else {
			amount = _depositInfo.amount.mul(timePassed).div(_depositInfo.vesting) - _depositInfo.amountWithdraw;
		}
		_depositInfo.amountWithdraw = _depositInfo.amountWithdraw.add(amount);

		IERC20 lpToken = IERC20(_depositInfo.lpToken);
		lpToken.safeTransfer(_depositInfo.beneficiary, amount);

		emit Withdraw(depositId, amount, _depositInfo.beneficiary);
	}

	function updateBeneficiary(uint256 _depositId, address _beneficiary) external override {

		require(_depositId <= depositId, "updateBeneficiary: depositId is too large");

		DepositInfo storage _depositInfo = depositInfo[_depositId];
		require(_beneficiary != address(0), "updateBeneficiary: _beneficiary address can't be 0");
		require(_depositInfo.beneficiary == address(msg.sender), "updateBeneficiary: not a beneficiary");

		_depositInfo.beneficiary = _beneficiary;

		emit UpdateBeneficiary(depositId, _beneficiary);
	}
	function calcTimePassed(uint256 _depositId) public view returns (uint256) {
		DepositInfo storage _depositInfo = depositInfo[_depositId];

		if (block.timestamp <= _depositInfo.depositTime.add(_depositInfo.lock))
			return 0;
		uint256 timePassed = (block.timestamp.sub(_depositInfo.depositTime)).sub(_depositInfo.lock);
		return timePassed;
	}
}