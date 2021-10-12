const CataPult = artifacts.require('CataPult');
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

contract('CataPult', async ([owner, user1, user2, user3, user4]) => {
  let cataPult;
  let vestingToken;

  beforeEach(async () => {
    cataPult = await CataPult.new();

    vestingToken = await VestingMock.new();
    
    (await cataPult.initialize(), {from: owner});
    await vestingToken.mintArbitrary(owner, wei('50000000000'));


    await vestingToken.transfer(user1, wei('10000000000'));
    await vestingToken.transfer(user2, wei('10000000000'));
    await vestingToken.transfer(user3, wei('10000000000'));
    await vestingToken.transfer(user4, wei('10000000000'));
    await vestingToken.approve(cataPult.address, wei('500000000000'), {from: user1});
    await vestingToken.approve(cataPult.address, wei('500000000000'), {from: user2});
    await vestingToken.approve(cataPult.address, wei('500000000000'), {from: user3});
    await vestingToken.approve(cataPult.address, wei('500000000000'), {from: user4});
  });
  describe('owner', () => {

    it('owner address should be correct', async () => {
      expect(await cataPult.owner()).to.equal(owner);
    });
  });

  describe('addTeam', () => {

    it('should revert if token address is 0', async () => {
      await expectRevert(cataPult.addTeam('0x0000000000000000000000000000000000000000', '10000000000000000000000', user1, '1634043349', '1644003538', '10000000000','10000000000', '20000000000', {from: owner}), "addTeam: token address cant be 0");
    });
    it('should revert if total raise is 0', async () => {
      await expectRevert(cataPult.addTeam(vestingToken.address, '0', user1, '1634003538', '1644003538', '10000000000',wei('10000'), wei('20000'), {from: owner}), "addTeam: _totalRaise must be greater than 0");
    });
    it('should revert if beneficiary is 0', async () => {
      await expectRevert(cataPult.addTeam(vestingToken.address, '10000000000000000000000', '0x0000000000000000000000000000000000000000', '1634003538', '1644003538', '10000000000','10000000000', wei('20000'), {from: owner}), "addTeam: _beneficiary address cant be 0");
    });
    it('should revert if start is before current timestamp', async () => {
      await expectRevert(cataPult.addTeam(vestingToken.address, '10000000000000000000000', user1, '1634003538', '1644003538', '10000000000',wei('10000'), wei('20000'), {from: owner}), "addTeam: startTime should be greater than current Time");
    });
    it('should revert if endTime is before startTime', async () => {
      await expectRevert(cataPult.addTeam(vestingToken.address, '10000000000000000000000', user1, '1644003538', '1644003538', '10000000000',wei('10000'), wei('20000'), {from: owner}), "addTeam: endTime should be greater than endTime");
    });
    it('should revert if price is 0', async () => {
      await expectRevert(cataPult.addTeam(vestingToken.address, '10000000000000000000000', user1, '1644003538', '1654003538', '0',wei('10000'), wei('20000'), {from: owner}), "addTeam: _price must be greater than 0");
    });
    it('should revert if minAlloc is 0', async () => {
      await expectRevert(cataPult.addTeam(vestingToken.address, '10000000000000000000000', user1, '1644003538', '1654003538', '10000000000',wei('0'), wei('20000'), {from: owner}), "addTeam: _minAlloc must be greater than 0");
    });
    it('should revert if maxAlloc is less than minAlloc', async () => {
      await expectRevert(cataPult.addTeam(vestingToken.address, '10000000000000000000000', user1, '1644003538', '1654003538', '10000000000',wei('10000'), wei('10000'), {from: owner}), "addTeam: _minAlloc must be greater than _maxAlloc");
    });

    it('should add a team', async () => {
      await cataPult.addTeam(vestingToken.address, '10000000000000000000000', user1, '1644003538', '1654003538', '10000000000',wei('10000'), wei('20000'), {from: owner})
      expect((await cataPult.teamId()).toString()).to.equal('1');  
    });
  });
  describe('deposit', () => {
    beforeEach(async () => {
      await cataPult.addTeam(vestingToken.address, wei('10000000000'), user1, '1644003538', '1654003538', '10000000000',wei('5000000000'), wei('10000000000'), {from: owner})
    });
    it('should revert if _teamID is too large', async () => {
      await expectRevert(cataPult.deposit('1', wei('10000000000'), {from: user1}), "deposit: _teamId is too large");
    });
    it('should revert if amount < minAlloc', async () => {
      await expectRevert(cataPult.deposit('0', wei('3000000000'), {from: user2}), "deposit: amount must be greater than minAlloc");
    });
    it('should revert if amount >  maxAlloc', async () => {
      await expectRevert(cataPult.deposit('0', wei('10000000001'), {from: user1}), "deposit: amount must be lower than maxAlloc");
    });
    it('should tranfser tokens', async () => {
      await cataPult.deposit('0', wei('10000000000'), {from: user1});
      expect(await vestingToken.balanceOf(user1)).to.be.a.bignumber.equal(wei('0'));
    });

    it('should revert if reached to limit', async () => {
      await cataPult.deposit('0', wei('5000000000'), {from: user3});
      await cataPult.deposit('0', wei('5000000000'), {from: user4});
      await expectRevert(cataPult.deposit('0', wei('5000000000'), {from: user1}), "deposit: already reached to limit");
    });
  });

  describe('updateBeneficiary', () => {
    beforeEach(async () => {
      await cataPult.addTeam(vestingToken.address, '10000000000000000000000', user1, '1644003538', '1654003538', '10000000000',wei('10000000000'), wei('20000000000'), {from: owner})
    });
    it('should revert if _teamID is too large', async () => {
      await expectRevert(cataPult.updateBeneficiary('1', user2, {from: owner}), "updateBeneficiary: _teamId is too large");
    });
    it('should revert if not a owner', async () => {
      await expectRevert(cataPult.updateBeneficiary('0', user2, {from: user2}), "Ownable: caller is not the owner");
    });

    it('should revert if Beneficiary address is 0', async () => {
      await expectRevert(cataPult.updateBeneficiary('0', '0x0000000000000000000000000000000000000000', {from: owner}), "updateBeneficiary: _beneficiary address can't be 0");
    });
  });

  describe('updateAllocAmounts', () => {
    beforeEach(async () => {
      await cataPult.addTeam(vestingToken.address, '10000000000000000000000', user1, '1644003538', '1654003538', '10000000000',wei('10000000000'), wei('20000000000'), {from: owner})
    });
    it('should revert if _teamID is too large', async () => {
      await expectRevert(cataPult.updateAllocAmounts('1', wei('13000000000'), wei('17000000000'), {from: owner}), "updateAllocAmounts: _teamId is too large");
    });
    it('should revert if not a owner', async () => {
      await expectRevert(cataPult.updateAllocAmounts('0', wei('13000000000'), wei('17000000000'), {from: user2}), "Ownable: caller is not the owner");
    });
    it('should revert if minAlloc is 0', async () => {
      await expectRevert(cataPult.updateAllocAmounts('0', wei('0'), wei('17000000000'), {from: owner}), "updateAllocAmounts: _minAlloc must be greater than 0");
    });
    it('should revert if maxAlloc is less than minAlloc', async () => {
      await expectRevert(cataPult.updateAllocAmounts('0', wei('13000000000'), wei('12000000000'), {from: owner}), "updateAllocAmounts: _minAlloc must be greater than _maxAlloc");
    });
  });

  describe('updateTimes', () => {
    beforeEach(async () => {
      await cataPult.addTeam(vestingToken.address, '10000000000000000000000', user1, '1644003538', '1654003538', '10000000000',wei('10000000000'), wei('20000000000'), {from: owner})
    });
    it('should revert if _teamID is too large', async () => {
      await expectRevert(cataPult.updateTimes('1', '1644103538', '1654003538', {from: owner}), "updateTimes: _teamId is too large");
    });
    it('should revert if not a owner', async () => {
      await expectRevert(cataPult.updateTimes('0', '1644103538', '1654003538', {from: user2}), "Ownable: caller is not the owner");
    });
    it('should revert if start Time is before than current time', async () => {
      await expectRevert(cataPult.updateTimes('0', '1634033143', '1654003538', {from: owner}), "updateTimes: startTime should be greater than current Time");
    });
    it('should revert if endTime is less than startTime', async () => {
      await expectRevert(cataPult.updateTimes('0', '1655003538', '1654003538', {from: owner}), "updateTimes: endTime should be greater than endTime");
    });
  });

  describe('withdraw', () => {
    beforeEach(async () => {
      await cataPult.addTeam(vestingToken.address, wei('10000000000'), user1, '1644043349', '1664003538', '10000000000',wei('5000000000'), wei('20000000000'), {from: owner})
      await cataPult.deposit('0', wei('5000000000'), {from: user3});
    });
    it('should revert if _teamID is too large', async () => {
      await expectRevert(cataPult.withdraw('1', {from: user1}), "withdraw: _teamId is too large");
    });
    it('should revert if not a beneficiary', async () => {
      await expectRevert(cataPult.withdraw('0', {from: user2}), "withdraw: not a beneficiary");
    });
    it('should revert if not reached to limit', async () => {
      await expectRevert(cataPult.withdraw('0', {from: user1}), "withdraw: not reached to limit or not ended");
    });
    it('should withdraw correct amount', async () => {
      await cataPult.deposit('0', wei('6000000000'), {from: user3});
      await cataPult.withdraw('0', {from: user1});
      console.log("wait vestingToken.balanceOf(user1)",await vestingToken.balanceOf(cataPult.address));
      expect(await vestingToken.balanceOf(user1)).to.be.a.bignumber.equal(wei('20000000000'));
    });
  });
});
