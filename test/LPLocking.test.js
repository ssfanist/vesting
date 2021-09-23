const LPLocking = artifacts.require('LPLocking');
const VestingMock = artifacts.require('./mock/VestingMock');

const {expectEvent, expectRevert, time, BN} = require('@openzeppelin/test-helpers');
const Web3 = require('web3');
const web3 = new Web3();

const {expect} = require('chai');

const wei = web3.utils.toWei;

const {
  advanceBlock,
  advanceTime,
  advanceTimeAndBlock,
  takeSnapshot,
  currentTime,
} = require("./helpers/utilsTest");
const { latestBlock } = require('@openzeppelin/test-helpers/src/time');

const SECONDS_IN_DAY = 86400;

contract('LPLocking', async ([owner, user1, user2, user3, user4]) => {
  let lpLocking;
  let vestingToken;

  beforeEach(async () => {
    lpLocking = await LPLocking.new();

    vestingToken = await VestingMock.new();
    

    await vestingToken.mintArbitrary(owner, wei('100000000'));


    await vestingToken.transfer(user1, wei('100000'));
    await vestingToken.transfer(user2, wei('100000'));
    await vestingToken.transfer(user3, wei('100000'));
    await vestingToken.transfer(user4, wei('100000'));

    await vestingToken.approve(lpLocking.address, wei('100000'), {from: user1});
    await lpLocking.deposit(vestingToken.address, wei('10000'), SECONDS_IN_DAY * 5 , SECONDS_IN_DAY * 10, user2, {from: user1});

  });

  describe('deposit', () => {

    it('should have tokens', async () => {
      expect(await vestingToken.balanceOf(user1)).to.be.a.bignumber.equal(wei('90000'));
      expect(await vestingToken.balanceOf(user2)).to.be.a.bignumber.equal(wei('100000'));
      expect(await vestingToken.balanceOf(user3)).to.be.a.bignumber.equal(wei('100000'));
      expect(await vestingToken.balanceOf(user4)).to.be.a.bignumber.equal(wei('100000'));
    });

    it('should transfer token', async () => {
      expect(await vestingToken.balanceOf(lpLocking.address)).to.be.a.bignumber.equal(wei('10000'));
    });

    it('should increase deposit ID', async () => {
      expect(await lpLocking.depositId()).to.be.a.bignumber.equal(new BN(1));
    });

  });
  describe('update beneficiary', () => {
    it('should update beneficiary address', async () => {
      await lpLocking.updateBeneficiary('1', user3, {from: user2});
      expect(await lpLocking.currentBeneficiary('1')).to.be.equal(user3);
    });
    it('should revert if 0 address', async () => {
      await expectRevert(lpLocking.updateBeneficiary('1', '0x0000000000000000000000000000000000000000', {from: user2}), "updateBeneficiary: _beneficiary address can't be 0");
    });
    it('should revert if invalid deposit ID', async () => {
      await expectRevert(lpLocking.updateBeneficiary('2', user3, {from: user2}), "updateBeneficiary: depositId is too large");
    });
    it('should revert if not a Beneficiary', async () => {
      await expectRevert(lpLocking.updateBeneficiary('1', user3, {from: user1}), "updateBeneficiary: not a beneficiary");
    });
  });

  describe('calcTimePassed', () => {

    it('should revert if still locked', async () => {
      await expectRevert(lpLocking.calcTimePassed('1'), "calcTimePassed: tokens are still locked");
    });
    
    it('should return passed seconds', async () => {
      await advanceTimeAndBlock(SECONDS_IN_DAY * 6);
      expect(await lpLocking.calcTimePassed('1')).to.be.a.bignumber.closeTo(new BN(SECONDS_IN_DAY),new BN('20'));
    });
  });

  describe('withdraw', () => {

    it('should revert if invalid deposit ID', async () => {
      await expectRevert(lpLocking.withdraw('2', {from: user1}), "withdraw: depositId is too large");
    });
    it('should revert if not a beneficiary', async () => {
      await advanceTimeAndBlock(SECONDS_IN_DAY * 6);
      await expectRevert(lpLocking.withdraw('1', {from: user3}), "withdraw: not a beneficiary");
    });
    it('should withdraw', async () => {
      await advanceTimeAndBlock(SECONDS_IN_DAY * 6);
      await lpLocking.withdraw('1', {from: user2});
      expect(await vestingToken.balanceOf(user2)).to.be.a.bignumber.equal(wei('101000'));

    });
  });
});
