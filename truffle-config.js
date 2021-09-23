 const HDWalletProvider = require('@truffle/hdwallet-provider');
 const dotenv = require('dotenv');
 dotenv.config();
 const mnemonic = "aac24b644a47b56133ac2dece0a94fcac33bd78c4bb106fc2f301df35dd9df7b";
 module.exports = {
   networks: {
     development: {
       host: '127.0.0.1', // Localhost (default: none)
       port: 8545, // Standard Ethereum port (default: none)
       network_id: '*', // Any network (default: none)
       gasLimit: 10000000, // <-- Use this high gas value
       gasPrice: 1,
     },
     mainnet: {
      provider: () => new HDWalletProvider([process.env.PRIVATE_KEY], `wss://mainnet.infura.io/ws/v3/${process.env.PROJECT_ID}`),
      network_id: 1,
      gas: 8000000,
      gasPrice: 140000000000,
      skipDryRun: true,
    },
     rinkeby: {
       provider: () => new HDWalletProvider([process.env.PRIVATE_KEY], `wss://rinkeby.infura.io/ws/v3/${process.env.PROJECT_ID}`),
       network_id: 4,
       gas: 10000000,
       skipDryRun: true,
     },
     ropsten: {
       provider: () => new HDWalletProvider([process.env.PRIVATE_KEY], `wss://ropsten.infura.io/ws/v3/${process.env.PROJECT_ID}`),
       network_id: 3,
       gas: 6721975,
       skipDryRun: true,
     },
     testnet: {
      provider: () => new HDWalletProvider(mnemonic, `https://data-seed-prebsc-1-s1.binance.org:8545`),
      network_id: 97,
      confirmations: 10,
      timeoutBlocks: 200,
      skipDryRun: true
    },
    bsc: {
      provider: () => new HDWalletProvider(mnemonic, `https://bsc-dataseed1.binance.org`),
      network_id: 56,
      confirmations: 10,
      timeoutBlocks: 200,
      skipDryRun: true
    },
   },
 
   mocha: {
     timeout: 400000,
   },
 
   plugins: ['truffle-plugin-verify', 'solidity-coverage'],
 
   api_keys: {
     etherscan: process.env.ETHERSCAN_KEY,
   },
 
   compilers: {
     solc: {
       version: '0.7.4',
       docker: false,
       settings: {
         optimizer: {
           enabled: true,
           runs: 200,
         },
         evmVersion: 'istanbul',
       },
     },
   },
 };
 