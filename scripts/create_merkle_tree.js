const ethers = require('ethers')
const fs = require('fs')
const { MerkleTree } = require('merkletreejs')
const keccak256 = require('keccak256')

let whitelist = fs.readFileSync('../test_whitelist.csv', 'utf-8').split('\n')

let leaves = []

let whitelistProofs = {
  proofs: {},
}

for (let i = 1; i < whitelist.length; i++) {
  let userInfo = whitelist[i].trim().split(',')
  let pid = userInfo[0]
  let address = userInfo[1]
  let amount = userInfo[2]
  leaves.push(
    ethers.utils.solidityPack(
      ['uint256', 'address', 'uint256'],
      [pid, address, amount]
    )
  )
  whitelistProofs['proofs'][address] = {
    pid: pid,
    amount: amount,
  }
}

let merkleTree = new MerkleTree(leaves, keccak256, {
  hashLeaves: true,
  sortPairs: true,
})
whitelistProofs['root'] = merkleTree.getHexRoot()

for (let address in whitelistProofs['proofs']) {
  let leaf = ethers.utils.solidityKeccak256(
    ['uint256', 'address', 'uint256'],
    [
      whitelistProofs['proofs'][address]['pid'],
      address,
      whitelistProofs['proofs'][address]['amount'],
    ]
  )
  let proof = merkleTree.getHexProof(leaf)
  whitelistProofs['proofs'][address]['proof'] = proof
}

let leaf = ethers.utils.solidityKeccak256(
  ['uint256', 'address', 'uint256'],
  ['0', '0xab7dd8c1523ca7087257b16e3ef1d565aaa423e9', 5]
)
let proof = merkleTree.getHexProof(leaf)
console.log(proof)

fs.writeFileSync(
  './whitelist-proofs.json',
  JSON.stringify(whitelistProofs, null, '\t'),
  'utf-8'
)
