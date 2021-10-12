// SPDX-License-Identifier: MIT

pragma solidity ^0.7.4;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
interface ICataPult {

	struct TeamInfo {
		address token;
		uint256 totalRaise;
		address beneficiary;
		uint256 startTime;
		uint256 endTime;
		uint256 price;
		uint256 minAlloc;
		uint256 maxAlloc;
		uint256 balance;
		uint256 totalDeposit;
	}
	event AddTeam(uint256 indexed _teamId, address _token, uint256 _totalRaise, address _beneficiary, uint256 _startTime, uint256 _endTime, uint256 _price, uint256 _minAlloc, uint256 _maxAlloc);
	event Deposit(uint256 indexed _teamId, address teamToken, uint256 _amount);
	event UpdateTimes(uint256 indexed _teamId, uint256 _startTime, uint256 _endTime);
	event UpdateAllocAmounts(uint256 indexed _teamId, uint256 _minAlloc, uint256 _maxAlloc);
	event UpdateBeneficiary(uint256 indexed _teamId, address _beneficiary);
	event Withdraw(uint256 indexed _teamId, uint256 amount, address _beneficiary);

	function updateBeneficiary(uint256 _teamId, address _beneficiary) external;
	function withdraw(uint256 _teamId) external;
}
