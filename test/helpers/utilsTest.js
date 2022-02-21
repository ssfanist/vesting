const { web3 } = require('@openzeppelin/test-helpers/src/setup')

advanceTime = (time) => {
  return new Promise((resolve, reject) => {
    web3.currentProvider.send(
      {
        jsonrpc: '2.0',
        method: 'evm_increaseTime',
        params: [time],
        id: new Date().getTime(),
      },
      (err, result) => {
        if (err) {
          return reject(err)
        }
        return resolve(result)
      }
    )
  })
}

advanceBlock = () => {
  return new Promise((resolve, reject) => {
    web3.currentProvider.send(
      {
        jsonrpc: '2.0',
        method: 'evm_mine',
        id: new Date().getTime(),
      },
      (err, result) => {
        if (err) {
          return reject(err)
        }
        const newBlockHash = web3.eth.getBlock('latest').hash

        return resolve(newBlockHash)
      }
    )
  })
}
latestBlock1 = () => {
  return new Promise((resolve, reject) => {
    web3.currentProvider.send(
      {
        jsonrpc: '2.0',
        method: 'evm_mine',
        id: new Date().getTime(),
      },
      (err, result) => {
        if (err) {
          return reject(err)
        }
        const newBlockHash = web3.eth.getBlock('latest')

        return resolve(newBlockHash)
      }
    )
  })
}

takeSnapshot = () => {
  return new Promise((resolve, reject) => {
    web3.currentProvider.send(
      {
        jsonrpc: '2.0',
        method: 'evm_snapshot',
        id: new Date().getTime(),
      },
      (err, snapshotId) => {
        if (err) {
          return reject(err)
        }
        return resolve(snapshotId)
      }
    )
  })
}

revertToSnapShot = (id) => {
  return new Promise((resolve, reject) => {
    web3.currentProvider.send(
      {
        jsonrpc: '2.0',
        method: 'evm_revert',
        params: [id],
        id: new Date().getTime(),
      },
      (err, result) => {
        if (err) {
          return reject(err)
        }
        return resolve(result)
      }
    )
  })
}

advanceTimeAndBlock = async (time) => {
  await advanceTime(time)
  await advanceBlock()
  return Promise.resolve(web3.eth.getBlock('latest'))
}
currentTime = async (time) => {
  return Promise.resolve(web3.eth.getBlock('latest'))
}

wei = (weiString) => new web3.utils.BN(weiString)

module.exports = {
  advanceTime,
  advanceBlock,
  advanceTimeAndBlock,
  takeSnapshot,
  revertToSnapShot,
  wei,
  currentTime,
  latestBlock1,
}
