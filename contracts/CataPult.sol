// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;

import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";
import "./interfaces/ICataPult.sol";
import "./interfaces/IStaking.sol";

contract CataPult is ICataPult, OwnableUpgradeable {
    using SafeMathUpgradeable for uint256;

    uint256 public pid;
    address STAKING;
    mapping(uint256 => PoolInfo) public poolInfo;

    function initialize(address staking) public initializer {
        __Ownable_init();
        STAKING = staking;
    }

    function addPool(
        uint256 _stakingId,
        address _token,
        uint256 _poolLimit,
        address _beneficiary,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _price,
        uint256 _minAlloc,
        uint256 _maxAlloc,
        uint256 _stakingRatio,
        bool _immWithdraw
    ) external onlyOwner {
        require(_token != address(0), "addPool: token address cant be 0");
        require(_poolLimit > 0, "addPool: _poolLimit must be greater than 0");
        require(
            _beneficiary != address(0),
            "addPool: _beneficiary address cant be 0"
        );
        require(
            _startTime >= block.timestamp,
            "addPool: startTime should be greater than current Time"
        );
        require(
            _endTime > _startTime,
            "addPool: endTime should be greater than startTime"
        );
        require(_price > 0, "addPool: _price must be greater than 0");
        require(
            _maxAlloc >= _minAlloc,
            "addPool: _minAlloc must be greater than _maxAlloc"
        );

        PoolInfo storage _poolInfo = poolInfo[pid];

        _poolInfo.stakingId = _stakingId;
        _poolInfo.token = _token;
        _poolInfo.poolLimit = _poolLimit;
        _poolInfo.beneficiary = _beneficiary;
        _poolInfo.startTime = _startTime;
        _poolInfo.endTime = _endTime;
        _poolInfo.price = _price;
        _poolInfo.minAlloc = _minAlloc;
        _poolInfo.maxAlloc = _maxAlloc;
        _poolInfo.stakingRatio = _stakingRatio;
        _poolInfo.immWithdraw = _immWithdraw;

        emit AddPool(
            pid,
            _stakingId,
            _token,
            _poolLimit,
            _beneficiary,
            _startTime,
            _endTime,
            _price,
            _minAlloc,
            _maxAlloc,
            _stakingRatio,
            _immWithdraw
        );
        pid = pid + 1;
    }

    function stake(uint256 _pid, uint256 _amount) external {
        require(_pid < pid, "deposit: _pid is too large");
        PoolInfo storage _poolInfo = poolInfo[_pid];
        uint256 stakedAmount = IStaking(STAKING).userStaked(
            _poolInfo.stakingId,
            msg.sender
        );
        require(
            _poolInfo.userStaked[msg.sender] + _amount <=
                stakedAmount * _poolInfo.stakingRatio,
            "CataPult: GREATER_THAN_STAKING_RATIO"
        );
        require(
            _poolInfo.userStaked[msg.sender] + _amount >= _poolInfo.minAlloc,
            "deposit: amount must be greater than minAlloc"
        );

        require(
            block.timestamp >= _poolInfo.startTime,
            "deposit: not started yet"
        );

        IERC20 token = IERC20(_poolInfo.token);
        uint256 availAmount;
        if (_poolInfo.poolLimit < _poolInfo.totalStaked.add(_amount)) {
            availAmount = _poolInfo.poolLimit.sub(_poolInfo.totalStaked);
        } else {
            availAmount = _amount;
        }
        require(
            _poolInfo.userStaked[msg.sender] + availAmount <=
                _poolInfo.maxAlloc,
            "deposit: amount must be lower than maxAlloc"
        );

        _poolInfo.userStaked[msg.sender] += availAmount;
        _poolInfo.totalStaked += availAmount;
        token.transferFrom(msg.sender, address(this), availAmount);

        emit Staked(_pid, _poolInfo.token, _amount);
    }

    function unStake(uint256 _pid) external {
        PoolInfo storage _poolInfo = poolInfo[_pid];
        require(_poolInfo.immWithdraw, "unStake: CANT_UNSTAKE");
        require(block.timestamp < _poolInfo.endTime, "unStake: ENDED");
        require(
            _poolInfo.userStaked[msg.sender] > 0,
            "unStake: NOT_STAKED_YET"
        );

        _poolInfo.totalStaked -= _poolInfo.userStaked[msg.sender];
        delete _poolInfo.userStaked[msg.sender];
        IERC20Upgradeable token = IERC20Upgradeable(_poolInfo.token);
        token.transfer(msg.sender, _poolInfo.userStaked[msg.sender]);
    }

    function claim(uint256 _pid) external {
        PoolInfo storage _poolInfo = poolInfo[_pid];
        require(block.timestamp >= _poolInfo.endTime, "claim: NOT_ENDED");

        IERC20Upgradeable token = IERC20Upgradeable(_poolInfo.token);
        uint256 price = _poolInfo.price;
        uint256 userStakedAmount = _poolInfo.userStaked[msg.sender];
        require(userStakedAmount > 0, "CataPult: NOT_STAKED_USER");
        _poolInfo.totalStaked -= _poolInfo.userStaked[msg.sender];

        token.transfer(msg.sender, userStakedAmount / price);
        delete _poolInfo.userStaked[msg.sender];
    }

    function userStaked(uint256 _pid, address _user)
        public
        view
        returns (uint256)
    {
        PoolInfo storage pool = poolInfo[_pid];
        return pool.userStaked[_user];
    }

    function totalStaked(uint256 _pid) public view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        return pool.totalStaked;
    }

    function updateBeneficiary(uint256 _pid, address _beneficiary)
        external
        override
        onlyOwner
    {
        require(_pid < pid, "updateBeneficiary: _pid is too large");
        PoolInfo storage _poolInfo = poolInfo[_pid];
        require(
            _beneficiary != address(0),
            "updateBeneficiary: _beneficiary address can't be 0"
        );

        _poolInfo.beneficiary = _beneficiary;

        emit UpdateBeneficiary(_pid, _beneficiary);
    }

    function updateAllocAmounts(
        uint256 _pid,
        uint256 _minAlloc,
        uint256 _maxAlloc
    ) external onlyOwner {
        require(_pid < pid, "updateAllocAmounts: _pid is too large");
        PoolInfo storage _poolInfo = poolInfo[_pid];
        require(
            _minAlloc > 0,
            "updateAllocAmounts: _minAlloc must be greater than 0"
        );
        require(
            _maxAlloc > _minAlloc,
            "updateAllocAmounts: _minAlloc must be greater than _maxAlloc"
        );

        _poolInfo.minAlloc = _minAlloc;
        _poolInfo.maxAlloc = _maxAlloc;

        emit UpdateAllocAmounts(_pid, _minAlloc, _maxAlloc);
    }

    function updateTimes(
        uint256 _pid,
        uint256 _startTime,
        uint256 _endTime
    ) external onlyOwner {
        require(_pid < pid, "updateTimes: _pid is too large");
        PoolInfo storage _poolInfo = poolInfo[_pid];
        require(
            _startTime >= block.timestamp,
            "updateTimes: startTime should be greater than current Time"
        );
        require(
            _startTime < _endTime,
            "updateTimes: endTime should be greater than startTime"
        );

        _poolInfo.startTime = _startTime;
        _poolInfo.endTime = _endTime;

        emit UpdateTimes(_pid, _startTime, _endTime);
    }

    function withdraw(uint256 _pid) external override {
        require(_pid < pid, "withdraw: _pid is too large");
        PoolInfo storage _poolInfo = poolInfo[_pid];

        require(
            address(msg.sender) == _poolInfo.beneficiary,
            "withdraw: not a beneficiary"
        );
        require(
            _poolInfo.totalStaked == _poolInfo.poolLimit ||
                block.timestamp >= _poolInfo.endTime,
            "withdraw: not reached to limit or not ended"
        );

        IERC20Upgradeable token = IERC20Upgradeable(_poolInfo.token);
        token.transfer(_poolInfo.beneficiary, _poolInfo.totalStaked);

        _poolInfo.totalStaked = 0;

        emit Withdraw(_pid, _poolInfo.totalStaked, _poolInfo.beneficiary);
    }
}
