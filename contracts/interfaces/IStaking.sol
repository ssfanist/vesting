// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;

interface IStaking {
    event RewardsSet(
        uint256 rewardPerBlock,
        uint256 firstBlockWithReward,
        uint256 lastBlockWithReward
    );
    event PoolAdded(
        uint256 indexed pid,
        string _name,
        address _stakingToken,
        address _rewardsToken,
        uint256 _allocSize,
        uint256 _minStakingLimit,
        uint256 _maxStakingLimit,
        uint256 _poolLimit,
        uint256 _startingBlock,
        uint256 _blocksAmount,
        bool _immWithdraw
    );
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);

    function pause() external;

    function unpause() external;

    function stake(uint256 _pid, uint256 _amount) external;

    function withdraw(uint256 _pid, uint256 _amount) external;

    function blocksWithRewardsPassed(uint256 _pid)
        external
        view
        returns (uint256);

    function rewardPerToken(uint256 _pid) external view returns (uint256);

    function earned(uint256 _pid, address _account)
        external
        view
        returns (uint256);

    function userStaked(uint256 _pid, address _user)
        external
        view
        returns (uint256);
}
