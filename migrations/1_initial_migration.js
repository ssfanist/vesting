const Migrations = artifacts.require("Migrations");
const LPLocking = artifacts.require("LPLocking");
const WalletLocking = artifacts.require("WalletLocking");


module.exports = function (deployer) {
  // deployer.deploy(Migrations);
  // deployer.deploy(LPLocking);
  deployer.deploy(WalletLocking);
};
