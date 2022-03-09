const Claiming = artifacts.require('Claiming')
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

const { latestBlock } = require('@openzeppelin/test-helpers/src/time')
const ether = require('@openzeppelin/test-helpers/src/ether')

const _name = 'TTEST'
const _allocSize = wei('10000')
const _price = '1000000000000000000'
const _whitelistRoot =
  '0x17c8a1c8761dfac767cbc743e335bd2dac42b38f01733cd59363d7ec7c8ba1dc'
var _beneficiary = ''
const ownerProof = [
  '0x99d24c9e8dd5b7e27d5d247a8b8cf6403483f0b14d83cde1ba33dae020e71085',
  '0xfae67561e6c4ac8b5243f0818e46a534537cb5c0ac522628bfa471090a904213',
  '0x9a1f28c5a5aca92ed2a87b76bfcc8745d3fb1d3d7b197dc950753a2c870e00ec',
  '0x5ad09d03b0fd44267dcd2b7df54c4d0aacbd33d0cc25777dc7fcf43d98d79efc',
  '0xfae614bec304934e7c09123f538f5bdb702ab76ab63f381c70e0d1d66c4b45fc',
]
const user1Proof = [
  '0x1cbdb6b7a9a74136f5513c3154fb8f88535523d7fa3f3baac381793bd5ec3a5f',
  '0xfae67561e6c4ac8b5243f0818e46a534537cb5c0ac522628bfa471090a904213',
  '0x9a1f28c5a5aca92ed2a87b76bfcc8745d3fb1d3d7b197dc950753a2c870e00ec',
  '0x5ad09d03b0fd44267dcd2b7df54c4d0aacbd33d0cc25777dc7fcf43d98d79efc',
  '0xfae614bec304934e7c09123f538f5bdb702ab76ab63f381c70e0d1d66c4b45fc',
]
contract('Claiming', async ([owner, user1, user2, user3, user4]) => {
  let claiming
  let purchaseToken
  let teamToken

  beforeEach(async () => {
    claiming = await Claiming.new()

    purchaseToken = await VestingMock.new()
    teamToken = await TeamToken.new()
    await claiming.initialize(owner)
    _beneficiary = user4
    await purchaseToken.mintArbitrary(owner, wei('500000'))
    await purchaseToken.transfer(user1, wei('10000'))
    await purchaseToken.transfer(user2, wei('10000'))

    await purchaseToken.approve(claiming.address, wei('10000'), {
      from: user1,
    })
    await purchaseToken.approve(claiming.address, wei('10000'), {
      from: user2,
    })
    await purchaseToken.approve(claiming.address, wei('10000'), {
      from: user3,
    })
    await purchaseToken.approve(claiming.address, wei('10000'), {
      from: user4,
    })
    await teamToken.mintArbitrary(owner, wei('5000000'))
    await teamToken.transfer(user3, wei('20000'))

    await teamToken.approve(claiming.address, wei('20000'), {
      from: user3,
    })
  })

  describe('addPool', () => {
    it('balance1', async () => {
      expect(await teamToken.balanceOf(user3)).to.be.a.bignumber.equal(
        wei('20000')
      )
    })

    it('should revert if dont have admin role', async () => {
      await expectRevert(
        claiming.addPool(
          _name,
          purchaseToken.address,
          teamToken.address,
          _allocSize,
          _price,
          _whitelistRoot,
          _beneficiary,
          { from: user1 }
        ),
        'Ownable: caller is not the owner'
      )
    })

    it('should add pool successfully', async () => {
      await claiming.addPool(
        _name,
        purchaseToken.address,
        teamToken.address,
        _allocSize,
        _price,
        _whitelistRoot,
        _beneficiary,
        { from: owner }
      )
      expect((await claiming.pid()).toString()).to.equal('1')
    })
  })

  describe('claim', () => {
    beforeEach(async () => {
      await claiming.addPool(
        _name,
        purchaseToken.address,
        teamToken.address,
        _allocSize,
        _price,
        _whitelistRoot,
        _beneficiary,
        { from: owner }
      )
      expect((await claiming.pid()).toString()).to.equal('1')

      await claiming.addPool(
        _name,
        purchaseToken.address,
        teamToken.address,
        _allocSize,
        _price,
        _whitelistRoot,
        _beneficiary,
        { from: owner }
      )

      expect((await claiming.pid()).toString()).to.equal('2')

      await claiming.deposit(0, wei('10000'), { from: user3 })
    })
    it('balance2', async () => {
      expect(await teamToken.balanceOf(user3)).to.be.a.bignumber.equal(
        wei('10000')
      )
    })
    it('should revert if already deposited', async () => {
      await claiming.deposit(0, wei('10000'), { from: user3 })
      expect((await claiming.poolInfo(0))[9]).to.be.a.bignumber.equal(
        wei('20000')
      )
    })

    it('should revert claiming if root incorrect', async () => {
      await expectRevert(
        claiming.claim(0, wei('500'), user1Proof, { from: owner }),
        'Claim: Invalid proof for whitelist'
      )
    })
    it('should claim correct amount', async () => {
      await claiming.claim(0, '15000000000000000000', user1Proof, {
        from: user1,
      })
      expect(await teamToken.balanceOf(user1)).to.be.a.bignumber.equal(
        '15000000000000000000'
      )
      expect(
        await purchaseToken.balanceOf(claiming.address)
      ).to.be.a.bignumber.equal('15000000000000000000')
    })

    it('should withdraw funds ', async () => {
      await claiming.claim(0, '15000000000000000000', user1Proof, {
        from: user1,
      })
      expect(await teamToken.balanceOf(user1)).to.be.a.bignumber.equal(
        '15000000000000000000'
      )
      await claiming.withdrawFunds(0, {
        from: user4,
      })
      expect(
        await purchaseToken.balanceOf((await claiming.poolInfo(0))[7])
      ).to.be.a.bignumber.equal('15000000000000000000')
    })
  })
})
