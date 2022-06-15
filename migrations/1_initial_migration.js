const Migrations = artifacts.require('Migrations')
const LPLocking = artifacts.require('LPLocking')
const WalletLocking = artifacts.require('WalletLocking')
const CataPult = artifacts.require('CataPult')
const Staking = artifacts.require('Staking')
const Claiming = artifacts.require('Claiming')
const LotteryDao = artifacts.require('LotteryDao')
const PriceOracleAggregator = artifacts.require('PriceOracleAggregator')

const { deployProxy } = require('@openzeppelin/truffle-upgrades')

module.exports = async function (deployer) {
  // deployer.deploy(Migrations);
  // deployer.deploy(LPLocking);
  // deployer.deploy(Claiming)
  const owner = '0x5CE31eA26833D0d5B3C62bF848bD4524c110064C'
  const oracle = '0xCb9352892fc2A8a03d94F0cbeBB067b90f3f1fa0'
  // const instance1 = await deployProxy(CataPult, [], {
  //   deployer,
  //   initializer: false,
  // })
  // console.log('LotteryDao Deployed:', instance1.address)
  // deployer.deploy(CataPult);

  // deployer.deploy(PriceOracleAggregator, owner)

  deployer.deploy(Staking, owner, oracle)
}
