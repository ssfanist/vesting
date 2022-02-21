// SPDX-License-Identifier: MIT

pragma solidity ^0.7.4;

import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "./interfaces/ICataPult.sol";

contract CataPult is ICataPult, OwnableUpgradeable {
    using SafeMathUpgradeable for uint256;
    using SafeERC20 for IERC20;

    uint256 public teamId;

    mapping(uint256 => TeamInfo) public teamInfo;

    function initialize() public initializer {
        __Ownable_init();
    }

    function addTeam(
        address _token,
        uint256 _totalRaise,
        address _beneficiary,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _price,
        uint256 _minAlloc,
        uint256 _maxAlloc
    ) external onlyOwner {
        require(_token != address(0), "addTeam: token address cant be 0");
        require(_totalRaise > 0, "addTeam: _totalRaise must be greater than 0");
        require(_beneficiary != address(0), "addTeam: _beneficiary address cant be 0");
        require(_startTime >= block.timestamp, "addTeam: startTime should be greater than current Time");
        require(_endTime > _startTime, "addTeam: endTime should be greater than startTime");
        require(_price > 0, "addTeam: _price must be greater than 0");
        require(_minAlloc > 0, "addTeam: _minAlloc must be greater than 0");
        require(_maxAlloc > _minAlloc, "addTeam: _minAlloc must be greater than _maxAlloc");

        TeamInfo storage _teamInfo = teamInfo[teamId];

        _teamInfo.token = _token;
        _teamInfo.totalRaise = _totalRaise;
        _teamInfo.beneficiary = _beneficiary;
        _teamInfo.startTime = _startTime;
        _teamInfo.endTime = _endTime;
        _teamInfo.price = _price;
        _teamInfo.minAlloc = _minAlloc;
        _teamInfo.maxAlloc = _maxAlloc;

        emit AddTeam(teamId, _token, _totalRaise, _beneficiary, _startTime, _endTime, _price, _minAlloc, _maxAlloc);
        teamId = teamId + 1;
    }

    function deposit(uint256 _teamId, uint256 _amount) external {
        require(_teamId < teamId, "deposit: _teamId is too large");
        TeamInfo storage _teamInfo = teamInfo[_teamId];
        require(_amount >= _teamInfo.minAlloc, "deposit: amount must be greater than minAlloc");
        require(_amount <= _teamInfo.maxAlloc, "deposit: amount must be lower than maxAlloc");
        require(_teamInfo.totalDeposit < _teamInfo.totalRaise, "deposit: already reached to limit");
        require(block.timestamp >= _teamInfo.startTime, "deposit: not started yet");

        IERC20 teamToken = IERC20(_teamInfo.token);
        uint256 availAmount;
        if (_teamInfo.totalRaise < _teamInfo.totalDeposit.add(_amount)) {
            availAmount = _teamInfo.totalRaise.sub(_teamInfo.totalDeposit);
            _teamInfo.balance += availAmount;
            _teamInfo.totalDeposit += availAmount;
            teamToken.safeTransferFrom(address(msg.sender), address(this), availAmount);
        } else {
            _teamInfo.balance += _amount;
            _teamInfo.totalDeposit += _amount;
            teamToken.safeTransferFrom(address(msg.sender), address(this), _amount);
        }

        emit Deposit(_teamId, _teamInfo.token, _amount);
    }

    function updateBeneficiary(uint256 _teamId, address _beneficiary) external override onlyOwner {
        require(_teamId < teamId, "updateBeneficiary: _teamId is too large");
        TeamInfo storage _teamInfo = teamInfo[_teamId];
        require(_beneficiary != address(0), "updateBeneficiary: _beneficiary address can't be 0");

        _teamInfo.beneficiary = _beneficiary;

        emit UpdateBeneficiary(_teamId, _beneficiary);
    }

    function updateAllocAmounts(
        uint256 _teamId,
        uint256 _minAlloc,
        uint256 _maxAlloc
    ) external onlyOwner {
        require(_teamId < teamId, "updateAllocAmounts: _teamId is too large");
        TeamInfo storage _teamInfo = teamInfo[_teamId];
        require(_minAlloc > 0, "updateAllocAmounts: _minAlloc must be greater than 0");
        require(_maxAlloc > _minAlloc, "updateAllocAmounts: _minAlloc must be greater than _maxAlloc");

        _teamInfo.minAlloc = _minAlloc;
        _teamInfo.maxAlloc = _maxAlloc;

        emit UpdateAllocAmounts(_teamId, _minAlloc, _maxAlloc);
    }

    function updateTimes(
        uint256 _teamId,
        uint256 _startTime,
        uint256 _endTime
    ) external onlyOwner {
        require(_teamId < teamId, "updateTimes: _teamId is too large");
        TeamInfo storage _teamInfo = teamInfo[_teamId];
        require(_startTime >= block.timestamp, "updateTimes: startTime should be greater than current Time");
        require(_startTime < _endTime, "updateTimes: endTime should be greater than startTime");

        _teamInfo.startTime = _startTime;
        _teamInfo.endTime = _endTime;

        emit UpdateTimes(_teamId, _startTime, _endTime);
    }

    function getBlockTimestamp() public view returns (uint256) {
        return block.timestamp;
    }

    function withdraw(uint256 _teamId) external override {
        require(_teamId < teamId, "withdraw: _teamId is too large");
        TeamInfo storage _teamInfo = teamInfo[_teamId];

        require(address(msg.sender) == _teamInfo.beneficiary, "withdraw: not a beneficiary");
        require(
            _teamInfo.totalDeposit == _teamInfo.totalRaise || block.timestamp >= _teamInfo.endTime,
            "withdraw: not reached to limit or not ended"
        );

        IERC20 teamToken = IERC20(_teamInfo.token);
        teamToken.safeTransfer(_teamInfo.beneficiary, _teamInfo.balance);

        _teamInfo.balance = 0;

        emit Withdraw(_teamId, _teamInfo.balance, _teamInfo.beneficiary);
    }
}
