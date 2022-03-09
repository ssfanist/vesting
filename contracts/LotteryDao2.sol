// SPDX-License-Identifier: MIT

pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/cryptography/MerkleProof.sol";
import "./interfaces/ILotteryDao.sol";

contract LotteryDao2 is ILotteryDao, Ownable {
    using SafeMathUpgradeable for uint256;
    using SafeERC20 for IERC20;
    using MerkleProof for bytes32[];

    bytes32 public _whitelistRoot;

    uint256 internal MULTIPLIER = 1e18;

    uint256 public poolId;
    mapping(uint256 => PoolInfo) public poolInfo;

    modifier checkPoolId(uint256 _poolId) {
        require(_poolId < poolId, "invalid PoolId");
        _;
    }

    modifier checkWinner(
        uint256 _poolId,
        address _addr,
        bytes32[] calldata _whitelistProof,
        uint256 _tickets
    ) {
        require(
            verifyWhitelist(_addr, _poolId, _tickets, _whitelistProof),
            "not a winner"
        );
        _;
    }

    function setWhitelistRoot(bytes32 merkleRoot) external onlyOwner {
        _whitelistRoot = merkleRoot;
    }

    function isWinner(uint256 _poolId) internal view returns (bool) {
        PoolInfo storage _poolInfo = poolInfo[_poolId];
        UserInfo memory _userInfo = _poolInfo.userdata[msg.sender];

        if (_userInfo.isRegistered && _userInfo.tickets > 0) return true;
        return false;
    }

    function addPool(InitialInfo memory _info) external onlyOwner {
        require(_info.totalRaise > 0, "totalRaise should greater than 0");
        require(
            _info.winningTickets > 0,
            "_winningTickets should greater than 0"
        );
        require(_info.beneficiary != address(0), "token address cant be 0");
        require(_info.tokenPrice > 0, "invalid token price");
        require(_info.teamTokenPrice > 0, "invalid token price");
        require(_info.teamToken != address(0), "_teamToken address cant be 0");
        require(_info.token != address(0), "token address cant be 0");
        require(
            block.timestamp < _info.openTime,
            "_openTime should be greater than openTime"
        );
        require(
            _info.openTime < _info.lotteryOpenTime,
            "_lotteryOpenTime should be greater than _openTime"
        );
        require(
            _info.lotteryOpenTime < _info.lotteryEndTime,
            "_lotteryEndTime should be greater than _lotteryOpenTime"
        );
        require(
            _info.lotteryEndTime < _info.endTime,
            "_endTime should be greater than _lotteryTime"
        );

        PoolInfo storage pool = poolInfo[poolId];
        pool.info = _info;

        poolId += 1;

        emit AddedPool(poolId, _info);
    }

    function updateBeneficiary(uint256 _poolId, address _beneficiary)
        external
        onlyOwner
        checkPoolId(_poolId)
    {
        PoolInfo storage _poolInfo = poolInfo[_poolId];
        require(
            _beneficiary != address(0),
            "updateBeneficiary: _beneficiary address cant be 0"
        );
        require(
            _poolInfo.info.beneficiary == msg.sender,
            "updateBeneficiary: not a beneficiary"
        );

        _poolInfo.info.beneficiary = _beneficiary;

        emit UpdateBeneficiary(_poolId, _beneficiary);
    }

    // Owner can set new Times
    function setTimes(
        uint256 _poolId,
        uint256 _openTime,
        uint256 _lotteryOpenTime,
        uint256 _lotteryEndTime,
        uint256 _endTime
    ) external onlyOwner checkPoolId(_poolId) {
        require(
            block.timestamp < _openTime,
            "_openTime should be greater than openTime"
        );
        require(
            _openTime < _lotteryOpenTime,
            "_lotteryOpenTime should be greater than _openTime"
        );
        require(
            _lotteryOpenTime < _lotteryEndTime,
            "_lotteryEndTime should be greater than _lotteryOpenTime"
        );
        require(
            _lotteryEndTime < _endTime,
            "_endTime should be greater than _lotteryTime"
        );

        PoolInfo storage pool = poolInfo[_poolId];
        pool.info.openTime = _openTime;
        pool.info.lotteryOpenTime = _lotteryOpenTime;
        pool.info.lotteryEndTime = _lotteryEndTime;
        pool.info.endTime = _endTime;

        emit SetTimes(
            _poolId,
            _openTime,
            _lotteryOpenTime,
            _lotteryEndTime,
            _endTime
        );
    }

    function setPrices(
        uint256 _poolId,
        uint256 _tokenPrice,
        uint256 _teamTokenPrice
    ) external onlyOwner checkPoolId(_poolId) {
        PoolInfo storage pool = poolInfo[_poolId];
        require(
            block.timestamp < pool.info.openTime,
            "_openTime should be greater than openTime"
        );

        pool.info.tokenPrice = _tokenPrice;
        pool.info.teamTokenPrice = _teamTokenPrice;

        emit SetPrice(_poolId, _tokenPrice, _teamTokenPrice);
    }

    function withdrawFunds(uint256 _poolId) external checkPoolId(_poolId) {
        PoolInfo storage pool = poolInfo[_poolId];
        require(
            pool.info.beneficiary == msg.sender,
            "withdrawFunds: not a beneficiary"
        );
        require(
            block.timestamp >= pool.info.endTime,
            "withdrawFunds: not finished yet"
        );
        require(
            IERC20(pool.info.token).balanceOf(address(this)) > 0,
            "withdrawFunds: insufficient balance"
        );
        IERC20(pool.info.token).transfer(pool.info.beneficiary, pool.poolRaise);

        emit WithdrawFunds(_poolId, msg.sender, pool.poolRaise);
    }

    function setMinAllocation(uint256 _poolId, uint256 _amount)
        external
        checkPoolId(_poolId)
    {
        PoolInfo storage pool = poolInfo[_poolId];
        require(
            block.timestamp <= pool.info.openTime,
            "setBlockHash: can set BlockHash before lotteryTime"
        );

        pool.minAllocation = _amount;

        emit SetMinAllocation(_poolId, _amount);
    }

    function lotteryRegistry(uint256 _poolId) external checkPoolId(_poolId) {
        PoolInfo storage pool = poolInfo[_poolId];

        UserInfo storage userdata = pool.userdata[msg.sender];
        bool isRegistered = userdata.isRegistered;

        require(block.timestamp <= pool.info.openTime, "registryTime ended");
        require(!isRegistered, "already registered");
        userdata.isRegistered = true;

        pool.registeredUsers.push(msg.sender);

        emit LotteryRegistry(_poolId);
    }

    function registeredUsersInfo(uint256 _poolId, address _user)
        public
        view
        returns (address, uint256)
    {
        PoolInfo storage pool = poolInfo[_poolId];
        require(pool.ticketPrice > 0, "Ticket Price not set yet");

        uint256 balance = IERC20(pool.info.token).balanceOf(_user);
        return (_user, balance / pool.ticketPrice);
    }

    function setTicketAllocation(uint256 _poolId, uint256 _amount)
        external
        onlyOwner
        checkPoolId(_poolId)
    {
        PoolInfo storage pool = poolInfo[_poolId];

        pool.ticketAllocation = _amount;

        emit SetTicketAllocation(_poolId, _amount);
    }

    function setTicketPrice(uint256 _poolId, uint256 _amount)
        external
        onlyOwner
        checkPoolId(_poolId)
    {
        PoolInfo storage pool = poolInfo[_poolId];

        pool.ticketPrice = _amount;

        emit SetTicketPrice(_poolId, _amount);
    }

    function participate(
        uint256 _poolId,
        uint256 _amount,
        bytes32[] calldata _whitelistProof,
        uint256 _tickets
    )
        external
        checkPoolId(_poolId)
        checkWinner(_poolId, msg.sender, _whitelistProof, _tickets)
    {
        PoolInfo storage pool = poolInfo[_poolId];
        UserInfo storage userdata = pool.userdata[msg.sender];

        pool.participatedAmount += _amount;
        userdata.participatedAmount += _amount;

        require(
            userdata.participatedAmount <= _tickets.mul(pool.ticketAllocation),
            "participate: reached to limit"
        );
        require(
            userdata.participatedAmount.mul(pool.info.tokenPrice) >=
                pool.minAllocation
        );
        require(
            userdata.participatedAmount.mul(pool.info.tokenPrice) <=
                pool.maxAllocation
        );
        require(
            pool.participatedAmount.mul(pool.info.tokenPrice) <=
                pool.info.totalRaise,
            "participate: POOL FILLED"
        );

        IERC20(pool.info.token).transferFrom(
            msg.sender,
            address(this),
            _amount
        );

        emit Participated(_poolId, _amount, msg.sender);
    }

    function lock(
        uint256 _poolId,
        address _token,
        uint256 _lock,
        uint256[] memory _percentages,
        uint256[] memory _vestingsPeriods
    ) external {
        require(_token != address(0), "Lock: token address can't be 0");
        require(
            _vestingsPeriods.length == _percentages.length,
            "Lock: Input arrary lengths mismatch"
        );

        PoolInfo storage pool = poolInfo[_poolId];

        require(
            block.timestamp >= pool.info.lotteryEndTime,
            "Lock: Pool not ended yet"
        );

        uint256 totalPercentages;
        for (uint256 i = 0; i < _percentages.length; i++) {
            totalPercentages = totalPercentages.add(_percentages[i]);
        }
        require(
            totalPercentages == 100,
            "deposit: sum of percentages should be 100"
        );

        require(
            pool.vestingAmount > 0,
            "deposit: must lock more than 0 tokens"
        );

        pool.vest.depositTime = block.timestamp;
        pool.vest.vestingPercentages = _percentages;
        pool.vest.vestingPeriods = _vestingsPeriods;
        pool.vest.lock = _lock;

        IERC20 token = IERC20(pool.info.teamToken);
        token.safeTransferFrom(
            address(msg.sender),
            address(this),
            pool.vestingAmount
        );

        emit Lock(_poolId, _token, _lock, _percentages, _vestingsPeriods);
    }

    function withdraw(uint256 _poolId) external {
        uint256 vestableAmount = _calcVestableAmount(_poolId);

        PoolInfo storage pool = poolInfo[_poolId];
        uint256 withdrawAmount = pool.userdata[msg.sender].withdrawAmount;

        IERC20 token = IERC20(pool.info.teamToken);
        uint256 transferAmount = vestableAmount.sub(withdrawAmount);

        pool.userdata[msg.sender].withdrawAmount = vestableAmount;

        token.safeTransfer(address(msg.sender), transferAmount);

        emit Withdraw(_poolId, transferAmount, address(msg.sender));
    }

    function _calcVestableAmount(uint256 _poolId)
        public
        view
        returns (uint256)
    {
        if (_poolId >= poolId) {
            return 0;
        }

        PoolInfo storage pool = poolInfo[_poolId];

        uint256 currentVesting = pool.vest.depositTime + pool.vest.lock;

        if (block.timestamp <= currentVesting) {
            return 0;
        }

        uint256 currentVestingIndex;
        uint256[] memory vestingPeriods = pool.vest.vestingPeriods;
        uint256[] memory vestingPercentages = pool.vest.vestingPercentages;
        for (uint256 i = 0; i < vestingPeriods.length; i++) {
            currentVestingIndex = i;
            if (currentVesting.add(vestingPeriods[i]) < block.timestamp) {
                currentVesting = currentVesting.add(vestingPeriods[i]);
            } else {
                break;
            }
        }
        uint256 vestableAmount;
        uint256 participatedAmount = pool
            .userdata[address(msg.sender)]
            .participatedAmount;

        uint256 vestablePrice = participatedAmount.mul(pool.info.tokenPrice);
        uint256 allocAmount = vestablePrice.div(pool.info.teamTokenPrice);

        for (uint256 i = 0; i < currentVestingIndex; i++) {
            vestableAmount =
                vestableAmount +
                allocAmount.mul(vestingPercentages[i]).div(100);
        }
        uint256 timePassed = block.timestamp.sub(currentVesting);
        if (timePassed > vestingPeriods[currentVestingIndex]) {
            timePassed = vestingPeriods[currentVestingIndex];
        }
        vestableAmount =
            vestableAmount +
            timePassed
                .mul(allocAmount)
                .mul(vestingPercentages[currentVestingIndex])
                .div(vestingPeriods[currentVestingIndex])
                .div(100);
        return vestableAmount;
    }

    function verifyWhitelist(
        address user,
        uint256 _poolId,
        uint256 tickets,
        bytes32[] calldata whitelistProof
    ) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(user, _poolId, tickets));
        return whitelistProof.verify(_whitelistRoot, leaf);
    }
}
