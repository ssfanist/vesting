// SPDX-License-Identifier: MIT

pragma solidity ^0.7.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IWalletLocking.sol";


contract WalletLocking is IWalletLocking, Ownable{
	using SafeMathUpgradeable for uint256;

	uint256 public depositId;
	mapping(uint256 => DepositInfo) public depositInfo;
	mapping(uint256 => mapping(address => uint256)) public allocInfo;
	mapping(uint256 => mapping(address => uint256)) public withdrawInfo;

	function lock(address _token, uint256 _lock, uint256[] memory _percentages, uint256[] memory _vestings, address[] memory _beneficiaries, uint256[] memory _allocAmounts) external override {

		require(_token != address(0), "deposit: token address can't be 0");
		require(_vestings.length == _percentages.length, "deposit: Input arrary lengths mismatch");
		require(_vestings.length == _allocAmounts.length, "deposit: Input arrary lengths mismatch");
		require(_vestings.length == _beneficiaries.length, "deposit: Input arrary lengths mismatch");


		DepositInfo storage _depositInfo = depositInfo[depositId];
		require(_depositInfo.totalAmount == 0, "deposit: already deposited");

		uint256 totalAmount;
		for (uint256 i = 0; i < _allocAmounts.length; i++) {
			totalAmount = totalAmount + _allocAmounts[i];
			allocInfo[depositId][_beneficiaries[i]] = _allocAmounts[i];
		}

		require(totalAmount > 0, "deposit: must lock more than 0 tokens");

		IERC20 token = IERC20(_token);
		token.transferFrom(_msgSender(), address(this), totalAmount);

		_depositInfo._token = _token;
		_depositInfo.lock = _lock;
		_depositInfo._percentages = _percentages;
		_depositInfo.vestings = _vestings;
		_depositInfo.depositTime = block.timestamp;
		_depositInfo.totalAmount = totalAmount;

		depositId = depositId + 1;

		emit Lock(depositId, _token, _lock, _vestings, _percentages);
	}

	function withdraw(uint256 _depositId) external override {

		uint256 vestableAmount = _calcVestableAmount(_depositId);

		require(vestableAmount > withdrawInfo[_depositId][_msgSender()], "withdraw: no tokens to withdraw at the moment");

		DepositInfo storage _depositInfo = depositInfo[_depositId];

		IERC20 token = IERC20(_depositInfo._token);
		uint256 transferAmount = vestableAmount.sub(withdrawInfo[_depositId][_msgSender()]);

		withdrawInfo[_depositId][_msgSender()] = withdrawInfo[_depositId][_msgSender()].add(transferAmount);
		token.transfer(_msgSender(), transferAmount);

		emit Withdraw(depositId, transferAmount, _msgSender());
	}
	function _calcVestableAmount(uint256 _depositId) public view returns (uint256) {

		require(_depositId < depositId, "_calcVestableAmount: depositId is too large");

		DepositInfo storage _depositInfo = depositInfo[_depositId];

		uint256 currentVesting = _depositInfo.depositTime + _depositInfo.lock;
		require(block.timestamp > currentVesting, "_calcVestableAmount: tokens are still locked");

		uint256 currentVestingIndex;
		for (uint256 i = 0; i < _depositInfo.vestings.length; i++) {
			currentVestingIndex = i;
			if (currentVesting.add(_depositInfo.vestings[i]) < block.timestamp ) {
				currentVesting = currentVesting.add(_depositInfo.vestings[i]);
			} else {
				break;
			}
		}

		uint256 vestableAmount;
		for (uint256 i = 0; i < currentVestingIndex; i++) {
			vestableAmount = vestableAmount + allocInfo[_depositId][_msgSender()].mul(_depositInfo._percentages[i]).div(100);
		}
		uint256 timePassed = block.timestamp.sub(currentVesting);
		if (timePassed > _depositInfo.vestings[currentVestingIndex]) {
			timePassed = _depositInfo.vestings[currentVestingIndex];
		}
		vestableAmount = vestableAmount + timePassed.mul(allocInfo[_depositId][_msgSender()]).mul(_depositInfo._percentages[currentVestingIndex]).div(_depositInfo.vestings[currentVestingIndex]).div(100);
		return vestableAmount;
	}
	function currentDepositId() public view returns (uint256) {
		return depositId;
	}
	function lengthOfVesting(uint256 _depositId) public view returns (uint256) {
		require(_depositId <= depositId, "withdraw: depositId is too large");
		DepositInfo storage _depositInfo = depositInfo[_depositId];

		return _depositInfo.vestings.length;
	}
}