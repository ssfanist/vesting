const stakingABI = require('./staking')
const ethers = require('ethers')
const fs = require('fs')
const path = require('path')
const { MerkleTree } = require('merkletreejs')
const keccak256 = require('keccak256')
const Web3 = require('web3')
const web3 = new Web3(
  new Web3.providers.HttpProvider('https://bsc-dataseed.binance.org/')
)
const contractInstance = new web3.eth.Contract(
  stakingABI,
  '0x09CbFCc18cE667eCc7eEB186883411dc5592C1ae'
)

const PID = '2'

let stakings = fs
  .readFileSync(path.resolve(__dirname, '../staking.csv'), 'utf-8')
  .split('\n')

let addresses = []
let amounts = []

let claimingInfo = {
  info: {},
}

;(async () => {
  for (let i = 1; i < stakings.length; i++) {
    let userInfo = stakings[i].trim().split(',')
    let user = userInfo[3]

    if (!addresses.includes(user)) {
      addresses.push(user)

      const amount = await contractInstance.methods.earned(PID, user).call()

      console.log(claimingInfo)
      if (Number(amount) > 0) {
        claimingInfo['info'][user] = { pid: PID, amount: amount }
      }
    }
  }
  fs.writeFileSync(
    './claiming.json',
    JSON.stringify(claimingInfo, null, '\t'),
    'utf-8'
  )
})()
