const Migrations = artifacts.require('Migrations')
const LPLocking = artifacts.require('LPLocking')
const WalletLocking = artifacts.require('WalletLocking')
const CataPult = artifacts.require('CataPult')
const Staking = artifacts.require('Staking')

const { deployProxy } = require('@openzeppelin/truffle-upgrades')

module.exports = async function (deployer) {
  // deployer.deploy(Migrations);
  // deployer.deploy(LPLocking);
  deployer.deploy(Staking)

  // const instance1 = await deployProxy(Staking, [], {
  //   deployer,
  //   initializer: false,
  // })

  // console.log('Staking Deployed:', instance1.address)

  // deployer.deploy(CataPult);
}
