// SPDX-License-Identifier: MIT

pragma solidity ^0.7.4;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
interface IRefundableDao {

	struct PoolInfo {
		uint256 tokenPrice;
		address token;
		address teamToken;
		uint256 startTime;
		uint256 endTime;
		address beneficiary;
		uint256 claimableAmount;
		uint256 deposit;
		mapping(address => UserInfo) userInfo;
	}

	struct UserInfo {
		uint256 deposit;
		uint256 claimableAmount;
	}

	event AddedPool(uint256 poolId, uint256 tokenPrice, address token, address teamToken, uint256 startTime, uint256 endTime, address beneficiary);
	event SetTimes(uint256 poolId, uint256 _startTime, uint256 _endTime);
	event SetPrice(uint256 poolId, uint256 _tokenPrice);
	event SetBeneficiaryAddress(uint256 poolId, address _beneficiary);
	event Deposited(uint256 poolId, uint256 amount);
	event Refunded(uint256 poolId, address user, uint256 amount);
	event Claimed(uint256 poolId, address user, uint256 amount);
	event WithdrawedUnUsedTokens(uint256 poolId, address beneficiary, uint256 amount);
	event Withdrawed(uint256 poolId, address beneficiary, uint256 amount);
}
