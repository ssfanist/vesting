const Staking = artifacts.require('Staking')
const VestingMock = artifacts.require('./mock/VestingMock')
const TeamToken = artifacts.require('./mock/TeamToken')

const {
  expectEvent,
  expectRevert,
  time,
  BN,
} = require('@openzeppelin/test-helpers')
const Web3 = require('web3')
const web3 = new Web3()

const { expect } = require('chai')
const keccak256 = require('keccak256')
const wei = web3.utils.toWei

const {
  advanceBlock,
  advanceTime,
  advanceTimeAndBlock,
  takeSnapshot,
  currentTime,
} = require('./helpers/utilsTest')
const { latestBlock } = require('@openzeppelin/test-helpers/src/time')

const SECONDS_IN_DAY = 86400
const TOKEN_PRICE = new BN(2)
const NEW_TOKEN_PRICE = new BN(3)

const _name = 'TTEST'
const _allocSize = wei('10000')
const _minStakingLimit = wei('500')
const _maxStakingLimit = wei('5000')
const _poolLimit = wei('10000')
var _startingBlock = 0
const _immWithdraw = true
const _immWithdrawFalse = true
const _blocksAmount = 10000

contract('Staking', async ([owner, user1, user2, user3, user4]) => {
  let staking
  let vestingToken
  let teamToken

  beforeEach(async () => {
    staking = await Staking.new()

    _startingBlock = (await latestBlock()).toNumber()
    console.log(_startingBlock, '_startingBlock')

    vestingToken = await VestingMock.new()
    teamToken = await TeamToken.new()
    await staking.initialize(owner)

    await vestingToken.mintArbitrary(owner, wei('50000'))
    await vestingToken.transfer(user1, wei('1000'))
    await vestingToken.transfer(user2, wei('1000'))
    await vestingToken.transfer(user3, wei('1000'))
    await vestingToken.transfer(user4, wei('10000'))

    await vestingToken.approve(staking.address, wei('10000'), {
      from: user1,
    })
    await vestingToken.approve(staking.address, wei('10000'), {
      from: user2,
    })
    await vestingToken.approve(staking.address, wei('10000'), {
      from: user3,
    })
    await vestingToken.approve(staking.address, wei('10000'), {
      from: user4,
    })
    await teamToken.mintArbitrary(staking.address, wei('5000'))
  })
  describe('addPool', () => {
    it('should revert if dont have admin role', async () => {
      await expectRevert(
        staking.addPool(
          _name,
          vestingToken.address,
          teamToken.address,
          _allocSize,
          _minStakingLimit,
          _maxStakingLimit,
          _poolLimit,
          _startingBlock + 20,
          _blocksAmount,
          _immWithdraw,
          { from: user1 }
        ),
        'Ownable: caller is not the owner'
      )
    })

    it('should add pool successfully', async () => {
      await staking.addPool(
        _name,
        vestingToken.address,
        teamToken.address,
        _allocSize,
        _minStakingLimit,
        _maxStakingLimit,
        _poolLimit,
        _startingBlock + 20,
        _blocksAmount,
        _immWithdraw,
        { from: owner }
      )
      expect((await staking.pid()).toString()).to.equal('1')
    })
  })

  describe('staking', () => {
    beforeEach(async () => {
      await staking.addPool(
        _name,
        vestingToken.address,
        teamToken.address,
        _allocSize,
        _minStakingLimit,
        _maxStakingLimit,
        _poolLimit,
        _startingBlock + 20,
        _blocksAmount,
        _immWithdraw,
        { from: owner }
      )
      expect((await staking.pid()).toString()).to.equal('1')

      for (var i = 0; i < 20; i++) {
        await advanceBlock()
      }
    })

    it('should stake correct amount', async () => {
      await staking.stake(0, wei('500'), {
        from: user1,
      })
      await staking.stake(0, wei('500'), {
        from: user1,
      })
      expect(await vestingToken.balanceOf(user1)).to.be.a.bignumber.equal(
        wei('0')
      )
    })

    it('should revert if amount less than minStakingLimit', async () => {
      await expectRevert(
        staking.stake(0, wei('300'), {
          from: user1,
        }),
        'Stake: _amount is too small'
      )
    })

    it('should revert if amount more than maxStakingLimit', async () => {
      await expectRevert(
        staking.stake(0, wei('6000'), {
          from: user4,
        }),
        'Stake: _amount is too high'
      )
    })
  })

  describe('withdraw', () => {
    var stakingBlock = 0

    beforeEach(async () => {
      await staking.addPool(
        _name,
        vestingToken.address,
        teamToken.address,
        _allocSize,
        _minStakingLimit,
        _maxStakingLimit,
        _poolLimit,
        _startingBlock + 20,
        _blocksAmount,
        _immWithdraw,
        { from: owner }
      )
      expect((await staking.pid()).toString()).to.equal('1')

      await staking.addPool(
        _name,
        vestingToken.address,
        teamToken.address,
        _allocSize,
        _minStakingLimit,
        _maxStakingLimit,
        _poolLimit,
        _startingBlock + 20,
        _blocksAmount,
        _immWithdrawFalse,
        { from: owner }
      )

      expect((await staking.pid()).toString()).to.equal('2')

      for (var i = 0; i < 20; i++) {
        await advanceBlock()
      }

      await staking.stake(0, wei('500'), {
        from: user1,
      })
      await staking.stake(0, wei('500'), {
        from: user1,
      })
      stakingBlock = (await latestBlock()).toNumber()
      await staking.stake(0, wei('1000'), {
        from: user2,
      })

      await staking.stake(1, wei('500'), {
        from: user3,
      })
    })

    it('should revert withdrawing if staked amount is not enough', async () => {
      await expectRevert(
        staking.withdraw(0, wei('500'), { from: owner }),
        'Insufficient staked amount'
      )
    })

    it('should withdraw correct amount', async () => {
      await staking.withdraw(0, wei('500'), { from: user1 })
      expect(await vestingToken.balanceOf(user1)).to.be.a.bignumber.equal(
        wei('500')
      )

      expect(await staking.userStaked(0, user1)).to.be.a.bignumber.equal(
        wei('500')
      )
      expect(await staking.totalStaked(0)).to.be.a.bignumber.equal(wei('1500'))
    })

    it('should withdraw correct amount', async () => {
      await staking.withdraw(0, wei('500'), { from: user1 })
      await staking.withdraw(0, wei('500'), { from: user1 })
      expect(await vestingToken.balanceOf(user1)).to.be.a.bignumber.equal(
        wei('1000')
      )
    })

    it('should calc correct reward amount', async () => {
      var blockPassed = (await latestBlock()).toNumber() - stakingBlock

      console.log('blockPassed', await staking.poolInfo(0))

      expect((await staking.poolInfo(0))[7]).to.be.a.bignumber.equal(wei('1'))
    })
  })
})
