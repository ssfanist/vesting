// SPDX-License-Identifier: MIT

pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ILotteryDao2 {
    struct InitialInfo {
        uint256 totalRaise;
        uint256 winningTickets;
        address beneficiary;
        uint256 openTime;
        uint256 lotteryOpenTime;
        uint256 lotteryEndTime;
        uint256 endTime;
        address token;
        uint256 tokenPrice;
        address teamToken;
        uint256 teamTokenPrice;
    }

    struct PoolInfo {
        InitialInfo info;
        VestingInfo vest;
        uint256 poolId;
        bytes32 blockHash;
        uint256 minTickets;
        address[] registeredUsers;
        address[] winners;
        uint256 ticketAllocation;
        uint256 ticketPrice;
        uint256 poolRaise;
        uint256 minAllocation;
        uint256 maxAllocation;
        uint256 vestingAmount;
        uint256 participatedAmount;
        mapping(address => UserInfo) userdata;
        mapping(uint256 => uint256) additionTickets;
    }

    struct VestingInfo {
        uint256 lock;
        uint256[] vestingPeriods;
        uint256[] vestingPercentages;
        uint256 depositTime;
    }

    struct UserInfo {
        bool isRegistered;
        uint256 tickets;
        uint256 vestingAmount;
        uint256 withdrawAmount;
        uint256 participatedAmount;
    }
    event Lock(
        uint256 indexed depositId,
        address _token,
        uint256 _lock,
        uint256[] _percentages,
        uint256[] _vestings,
        address[] _beneficiaries,
        uint256[] _allocAmounts
    );
    event AddedPool(uint256 id, InitialInfo info);
    event UpdateBeneficiary(uint256 _poolId, address _beneficiary);
    event SetTimes(
        uint256 _poolId,
        uint256 _openTime,
        uint256 _lotteryOpenTime,
        uint256 _lotteryEndTime,
        uint256 _endTime
    );
    event SetPrice(
        uint256 _poolId,
        uint256 _tokenPrice,
        uint256 _teamTokenPrice
    );
    event WithdrawFunds(uint256 _poolId, address user, uint256 _poolRaise);
    event SetBlockHash(uint256 _poolId, bytes32 _blockHash);
    event SetMinAllocation(uint256 _poolId, uint256 _amount);
    event LotteryRegistry(uint256 _poolId);
    event SetMinTickets(uint256 _poolId, uint256 _min);
    event RunLottery(uint256 _poolId);
    event SetTicketAllocation(uint256 _poolId, uint256 _amount);
    event SetTicketPrice(uint256 _poolId, uint256 _amount);
    event Participated(uint256 _poolId, uint256 _amount, address user);
    event Lock(
        uint256 _poolId,
        address _token,
        uint256 _lock,
        uint256[] _percentages,
        uint256[] _vestingsPeriods
    );
    event Withdraw(uint256 _poolId, uint256 transferAmount, address user);
}
