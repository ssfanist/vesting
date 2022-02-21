const RefundableDao = artifacts.require('RefundableDao')
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
var START_TIME = 0
var END_TIME = 0

contract('LotteryDao2', async ([owner, user1, user2, user3, user4]) => {
  let refundableDao
  let vestingToken
  let teamToken

  beforeEach(async () => {
    refundableDao = await LotteryDao2.new()

    vestingToken = await VestingMock.new()
    teamToken = await TeamToken.new()

    signer = web3.eth.accounts.privateKeyToAccount(SIGNER_KEY).address

    START_TIME = parseInt((await refundableDao.getBlockTimestamp()).toString())
    END_TIME = START_TIME + 5000

    await vestingToken.mintArbitrary(owner, wei('5000'))
    await vestingToken.transfer(user1, wei('1000'))
    await vestingToken.transfer(user2, wei('1000'))
    await vestingToken.transfer(user3, wei('1000'))
    await vestingToken.transfer(user4, wei('1000'))

    await vestingToken.approve(refundableDao.address, wei('10000'), {
      from: user1,
    })
    await teamToken.mintArbitrary(refundableDao.address, wei('5000'))

    // let quote = new BN(web3.utils.toWei('100', 'ether'));
    // SIGNATURE = await signQuote(vestingToken.address, user1, quote);
    SIGNATURE = await signQuote()
    quote = new BN(web3.utils.toWei('100', 'ether'))
  })

  describe('addPool', () => {
    it('should revert if dont have admin role', async () => {
      await expectRevert(
        refundableDao.addPool(
          TOKEN_PRICE,
          vestingToken.address,
          teamToken.address,
          START_TIME,
          END_TIME,
          user1,
          { from: user1 }
        ),
        '!admin'
      )
    })
    it('should revert if price is zero', async () => {
      await expectRevert(
        refundableDao.addPool(
          0,
          vestingToken.address,
          teamToken.address,
          START_TIME,
          END_TIME,
          user1,
          { from: owner }
        ),
        'invalid token price'
      )
    })
    it('should revert if teamToken address is zero', async () => {
      await expectRevert(
        refundableDao.addPool(
          TOKEN_PRICE,
          vestingToken.address,
          ZERO_ADDRESS,
          START_TIME,
          END_TIME,
          user1,
          { from: owner }
        ),
        'token address cant be 0'
      )
    })
    it('should revert if startTime >= endTime', async () => {
      await expectRevert(
        refundableDao.addPool(
          TOKEN_PRICE,
          vestingToken.address,
          teamToken.address,
          START_TIME,
          START_TIME,
          user1,
          { from: owner }
        ),
        'endTime should be greater than startTime'
      )
    })
    it('should revert if beneficiary address is zero', async () => {
      await expectRevert(
        refundableDao.addPool(
          TOKEN_PRICE,
          vestingToken.address,
          teamToken.address,
          START_TIME,
          END_TIME,
          ZERO_ADDRESS,
          { from: owner }
        ),
        'token address cant be 0'
      )
    })

    it('should add pool successfully', async () => {
      await refundableDao.addPool(
        TOKEN_PRICE,
        vestingToken.address,
        teamToken.address,
        START_TIME,
        END_TIME,
        user1,
        { from: owner }
      )
      expect((await refundableDao.id()).toString()).to.equal('1')
    })
  })

  it('should recover signer from quote signature', async () => {
    let quoteSignature = await signQuote()

    let recoveredSigner = await refundableDao.recoverSigner(
      user1,
      quote,
      quoteSignature
    )
    expect(recoveredSigner).to.be.equal(signer)
  })

  describe('setTimes', () => {
    beforeEach(async () => {
      await refundableDao.addPool(
        TOKEN_PRICE,
        vestingToken.address,
        teamToken.address,
        START_TIME,
        END_TIME,
        user1,
        { from: owner }
      )
    })

    it('should revert if startTime >= endTime', async () => {
      await expectRevert(
        refundableDao.setTimes(0, START_TIME, START_TIME, { from: owner }),
        'endTime should be greater than startTime'
      )
    })

    it('should revert if dont have admin role', async () => {
      await expectRevert(
        refundableDao.setTimes(0, START_TIME + 1000, END_TIME + 1000, {
          from: user1,
        }),
        '!admin'
      )
    })
  })

  describe('setPrice', () => {
    beforeEach(async () => {
      await refundableDao.addPool(
        TOKEN_PRICE,
        vestingToken.address,
        teamToken.address,
        START_TIME,
        END_TIME,
        user1,
        { from: owner }
      )
    })

    it('should revert if the price is 0', async () => {
      await expectRevert(
        refundableDao.setPrice(0, 0, { from: owner }),
        'invalid token price'
      )
    })

    it('should set token price correctly', async () => {
      await refundableDao.setPrice(0, NEW_TOKEN_PRICE, { from: owner })
    })
  })

  describe('setBeneficiary', () => {
    beforeEach(async () => {
      await refundableDao.addPool(
        TOKEN_PRICE,
        vestingToken.address,
        teamToken.address,
        START_TIME,
        END_TIME,
        user1,
        { from: owner }
      )
    })

    it('should revert if the address is 0', async () => {
      await expectRevert(
        refundableDao.setBeneficiaryAddress(0, ZERO_ADDRESS, { from: owner }),
        'token address cant be 0'
      )
    })

    it('should set beneficiary correctly', async () => {
      await refundableDao.setBeneficiaryAddress(0, user2, { from: owner })
    })
  })

  describe('deposit', () => {
    beforeEach(async () => {
      await refundableDao.addPool(
        TOKEN_PRICE,
        vestingToken.address,
        teamToken.address,
        START_TIME,
        END_TIME,
        user1,
        { from: owner }
      )
    })

    it('should deposit correct amount', async () => {
      await refundableDao.deposit(0, wei('500'), quote, SIGNATURE, {
        from: user1,
      })
      expect(await vestingToken.balanceOf(user1)).to.be.a.bignumber.equal(
        wei('500')
      )
    })
  })

  describe('withdraw', () => {
    beforeEach(async () => {
      await refundableDao.addPool(
        TOKEN_PRICE,
        vestingToken.address,
        teamToken.address,
        START_TIME,
        END_TIME,
        user2,
        { from: owner }
      )
      await refundableDao.deposit(0, wei('500'), quote, SIGNATURE, {
        from: user1,
      })
    })

    it('should revert withdrawing if not a beneficiary', async () => {
      await expectRevert(
        refundableDao.withdraw(0, { from: owner }),
        'withdraw: not a beneficiary'
      )
    })

    it('should withdraw correct amount', async () => {
      await refundableDao.withdraw(0, { from: user2 })
      expect(await vestingToken.balanceOf(user2)).to.be.a.bignumber.equal(
        wei('1500')
      )
    })
  })

  describe('refund', () => {
    beforeEach(async () => {
      await refundableDao.addPool(
        TOKEN_PRICE,
        vestingToken.address,
        teamToken.address,
        START_TIME,
        END_TIME,
        user2,
        { from: owner }
      )
      await refundableDao.deposit(0, wei('500'), quote, SIGNATURE, {
        from: user1,
      })
    })

    it('should revert withdrawing if 24 hours passed after pool ended', async () => {
      await advanceTimeAndBlock(SECONDS_IN_DAY * 2)
      await expectRevert(
        refundableDao.refund(0, { from: user1 }),
        'refund: cant refund after 24 hrs'
      )
    })

    it('should refund if not a beneficiary', async () => {
      await refundableDao.refund(0, { from: user1 })
      expect(await vestingToken.balanceOf(user1)).to.be.a.bignumber.equal(
        wei('1000')
      )
    })
  })

  describe('claim', () => {
    beforeEach(async () => {
      await refundableDao.addPool(
        TOKEN_PRICE,
        vestingToken.address,
        teamToken.address,
        START_TIME,
        END_TIME,
        user2,
        { from: owner }
      )
      await refundableDao.deposit(0, wei('500'), quote, SIGNATURE, {
        from: user1,
      })
    })

    it('should revert if not IDO not ended', async () => {
      await expectRevert(
        refundableDao.claim(0, { from: user1 }),
        'claim: not ended yet'
      )
    })

    it('should claim correct amount of team token', async () => {
      await advanceTimeAndBlock(SECONDS_IN_DAY * 2)
      await refundableDao.claim(0, { from: user1 })
      expect(await teamToken.balanceOf(user1)).to.be.a.bignumber.equal(
        new BN('1000')
      )
    })
  })

  describe('withdrawUnUsedTokens', () => {
    beforeEach(async () => {
      await refundableDao.addPool(
        TOKEN_PRICE,
        vestingToken.address,
        teamToken.address,
        START_TIME,
        END_TIME,
        user2,
        { from: owner }
      )
      await refundableDao.deposit(0, wei('500'), quote, SIGNATURE, {
        from: user1,
      })
    })

    it('should revert if not a beneficiary', async () => {
      await expectRevert(
        refundableDao.withdrawUnUsedTokens(0, { from: user3 }),
        'withdrawUnUsedTokens: not a beneficiary'
      )
    })

    it('should withdraw correct amount of unused team token', async () => {
      await refundableDao.withdrawUnUsedTokens(0, { from: user2 })
      console.log(
        'teamToken.balanceOf(user1)',
        await teamToken.balanceOf(user2)
      )
      expect(await teamToken.balanceOf(user2)).to.be.a.bignumber.equal(
        wei('4000')
      )
    })
  })
  async function signQuote() {
    let quote = new BN(web3.utils.toWei('100', 'ether'))
    let data = web3.eth.abi.encodeParameters(
      ['address', 'uint256'],
      [user1, quote]
    )
    let dataHash = web3.utils.keccak256(data)
    let signatureObj = web3.eth.accounts.sign(dataHash, SIGNER_KEY)
    return signatureObj.signature
  }
})
