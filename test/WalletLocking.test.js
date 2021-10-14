const WalletLocking = artifacts.require('WalletLocking');
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

contract('WalletLocking', async ([owner, user1, user2, user3, user4]) => {
  let walletLocking;
  let vestingToken;

  beforeEach(async () => {
    walletLocking = await WalletLocking.new();

    vestingToken = await VestingMock.new();
    

    await vestingToken.mintArbitrary(owner, wei('100000000'));


    await vestingToken.transfer(user1, wei('100000'));

    await vestingToken.approve(walletLocking.address, wei('100000'), {from: user1});
    await walletLocking.lock(vestingToken.address, SECONDS_IN_DAY * 5 , [50,25,25], [SECONDS_IN_DAY * 10,SECONDS_IN_DAY * 10,SECONDS_IN_DAY * 20],[user1,user2,user3],[wei('10000'),wei('20000'),wei('20000')], {from: user1});
  });

  describe('lock', () => {

    it('should revert if address == 0', async () => {
      await expectRevert(walletLocking.lock('0x0000000000000000000000000000000000000000', SECONDS_IN_DAY * 5 , [50,50,50], [SECONDS_IN_DAY * 10,SECONDS_IN_DAY * 10,SECONDS_IN_DAY * 20],[user1, user2, user3], [wei('10000'),wei('20000'),wei('20000')], {from: user1}), "deposit: token address can't be 0");
    });
    it('should revert if arrary lengths mismatch', async () => {
      await expectRevert(walletLocking.lock(vestingToken.address, SECONDS_IN_DAY * 5 , [50,50,50,50], [SECONDS_IN_DAY * 10,SECONDS_IN_DAY * 10,SECONDS_IN_DAY * 20],[user1,user2,user3],[wei('10000'),wei('20000'),wei('20000')], {from: user1}), "deposit: Input arrary lengths mismatch");
    });

    it('should have correct balance', async () => {
      expect(await vestingToken.balanceOf(user1)).to.be.a.bignumber.equal(wei('50000'));
      expect(await vestingToken.balanceOf(user2)).to.be.a.bignumber.equal(wei('0'));
      expect(await vestingToken.balanceOf(user3)).to.be.a.bignumber.equal(wei('0'));
      expect(await vestingToken.balanceOf(user4)).to.be.a.bignumber.equal(wei('0'));
    });

    it('should transfer token', async () => {
      expect(await vestingToken.balanceOf(walletLocking.address)).to.be.a.bignumber.equal(wei('50000'));
    });

    it('should increase deposit ID', async () => {
      expect(await walletLocking.depositId()).to.be.a.bignumber.equal(new BN(1));
    });

  });



  describe('_calcVestableAmount', () => {

    it('should calculate vestable amounts1', async () => {
      await advanceTimeAndBlock(SECONDS_IN_DAY * 6);
      expect(await walletLocking._calcVestableAmount('0', {from: user1})).to.be.a.bignumber.closeTo(wei('500'),wei('0.01'));
    });
    it('should calculate vestable amounts2', async () => {
      await advanceTimeAndBlock(SECONDS_IN_DAY * 6);
      expect(await walletLocking._calcVestableAmount('0', {from: user2})).to.be.a.bignumber.closeTo(wei('1000'),wei('0.01'));
    });
    
    it('should calculate vestable amounts3', async () => {
      await advanceTimeAndBlock(SECONDS_IN_DAY * 16);
      expect(await walletLocking._calcVestableAmount('0', {from: user1})).to.be.a.bignumber.closeTo(wei('5250'),wei('0.01'));
    });
    it('should calculate vestable amounts4', async () => {
      await advanceTimeAndBlock(SECONDS_IN_DAY * 14);
      expect(await walletLocking._calcVestableAmount('0', {from: user1})).to.be.a.bignumber.closeTo(wei('4500'), wei('0.01'));
    });
    it('should calculate vestable amounts5', async () => {
      await advanceTimeAndBlock(SECONDS_IN_DAY * 15);
      expect(await walletLocking._calcVestableAmount('0', {from: user1})).to.be.a.bignumber.closeTo(wei('5000'),wei('0.01'));
    });
    it('should calculate vestable amounts6', async () => {
      await advanceTimeAndBlock(SECONDS_IN_DAY * 25);
      expect(await walletLocking._calcVestableAmount('0', {from: user1})).to.be.a.bignumber.closeTo(wei('7500'),wei('0.01'));
    });
    it('should calculate vestable amounts7', async () => {
      await advanceTimeAndBlock(SECONDS_IN_DAY * 29);
      expect(await walletLocking._calcVestableAmount('0', {from: user1})).to.be.a.bignumber.closeTo(wei('8000'),wei('0.01'));
    });
  });

  describe('withdraw', () => {

    it('should revert if tokens are locked', async () => {
      await advanceTimeAndBlock(SECONDS_IN_DAY * 1);
      await expectRevert(walletLocking.withdraw('0', {from: user2}), "withdraw: no tokens to withdraw at the moment");
    });

    it('should withdraw correct amounts1', async () => {
      await advanceTimeAndBlock(SECONDS_IN_DAY * 65);
      await walletLocking.withdraw('0', {from: user1});
      expect(await vestingToken.balanceOf(user1)).to.be.a.bignumber.closeTo(wei('60000'),wei('0.01'));
    });
    it('should withdraw correct amounts2', async () => {
      await advanceTimeAndBlock(SECONDS_IN_DAY * 16);
      await walletLocking.withdraw('0', {from: user1});
      expect(await vestingToken.balanceOf(user1)).to.be.a.bignumber.closeTo(wei('55250'),wei('0.01'));
    });
    it('should withdraw correct amounts3', async () => {
      await advanceTimeAndBlock(SECONDS_IN_DAY * 16);
      await walletLocking.withdraw('0', {from: user1});
      expect(await vestingToken.balanceOf(user1)).to.be.a.bignumber.closeTo(wei('55250'),wei('0.01'));
      await advanceTimeAndBlock(SECONDS_IN_DAY * 5);
      expect(await walletLocking._calcVestableAmount('0', {from: user1})).to.be.a.bignumber.closeTo(wei('6500'),wei('0.01'));
      await walletLocking.withdraw('0', {from: user1});
      expect(await vestingToken.balanceOf(user1)).to.be.a.bignumber.closeTo(wei('56500'),wei('0.01'));
    });

    it('should withdraw correct amounts4', async () => {
      await advanceTimeAndBlock(SECONDS_IN_DAY * 35);
      await walletLocking.withdraw('0', {from: user1});
      expect(await vestingToken.balanceOf(user1)).to.be.a.bignumber.closeTo(wei('58750'),wei('0.002'));
      await advanceTimeAndBlock(SECONDS_IN_DAY * 35);
      await walletLocking.withdraw('0', {from: user1});
      expect(await vestingToken.balanceOf(user1)).to.be.a.bignumber.closeTo(wei('60000'),wei('0.003'));
    });

    it('should withdraw correct amounts4', async () => {

      await advanceTimeAndBlock(SECONDS_IN_DAY * 125);
      await walletLocking.withdraw('0', {from: user1});
      expect(await vestingToken.balanceOf(user1)).to.be.a.bignumber.closeTo(wei('60000'),wei('0.01'));
    });
  });

});
