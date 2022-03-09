const Migrations = artifacts.require('Migrations')
const LPLocking = artifacts.require('LPLocking')
const WalletLocking = artifacts.require('WalletLocking')
const CataPult = artifacts.require('CataPult')
const Staking = artifacts.require('Staking')
const Claiming = artifacts.require('Claiming')

const { deployProxy } = require('@openzeppelin/truffle-upgrades')

module.exports = async function (deployer) {
  // deployer.deploy(Migrations);
  // deployer.deploy(LPLocking);
  deployer.deploy(Claiming)
  // const instance1 = await deployProxy(Claiming, [], {
  //   deployer,
  //   initializer: false,
  // })
  // console.log('Staking Deployed:', instance1.address)
  // deployer.deploy(CataPult);
}
