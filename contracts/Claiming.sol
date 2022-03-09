// SPDX-License-Identifier: MIT

pragma solidity ^0.7.4;

import "@openzeppelin/contracts-upgradeable/math/MathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/cryptography/MerkleProofUpgradeable.sol";
import "./interfaces/IClaiming.sol";

contract Claiming is
    IClaiming,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable
{
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using MerkleProofUpgradeable for bytes32[];

    uint256 public pid;
    struct PoolInfo {
        string name;
        IERC20Upgradeable purchaseToken;
        IERC20Upgradeable claimToken;
        uint256 allocSize;
        uint256 price;
        bytes32 whitelistRoot;
        uint256 claimed;
        address beneficiary;
        uint256 purchasedAmount;
        uint256 deposited;
        mapping(address => bool) isClaimed;
    }

    mapping(uint256 => PoolInfo) public poolInfo;

    function initialize(address _owner) external override initializer {
        __Ownable_init();
        transferOwnership(_owner);
        __Pausable_init();
        __ReentrancyGuard_init();
    }

    function addPool(
        string memory _name,
        address _purchaseToken,
        address _claimToken,
        uint256 _allocSize,
        uint256 _price,
        bytes32 _whitelistRoot,
        address _beneficiary
    ) external onlyOwner {
        PoolInfo storage pool = poolInfo[pid];

        pool.name = _name;
        pool.purchaseToken = IERC20Upgradeable(_purchaseToken);
        pool.claimToken = IERC20Upgradeable(_claimToken);
        pool.allocSize = _allocSize;
        pool.price = _price;
        pool.whitelistRoot = _whitelistRoot;
        pool.beneficiary = _beneficiary;

        PoolAdded(
            pid,
            _name,
            _purchaseToken,
            _claimToken,
            _allocSize,
            _price,
            _whitelistRoot,
            _beneficiary
        );
        pid += 1;
    }

    function claim(
        uint256 _pid,
        uint256 _amount,
        bytes32[] calldata _whitelistProof
    ) public override nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];

        require(_amount > 0, "Claim: Amount should be greater then 0");
        require(
            pool.claimed + _amount <= pool.deposited,
            "Claim: No tokens left to claim"
        );
        require(!pool.isClaimed[msg.sender], "Claim: user already claimed");
        require(
            verifyWhitelist(_pid, msg.sender, _amount, _whitelistProof),
            "Claim: Invalid proof for whitelist"
        );

        if (pool.price > 0) {
            uint256 purchaseAmount = _amount.mul(pool.price).div(1e18);
            pool.purchaseToken.transferFrom(
                msg.sender,
                address(this),
                purchaseAmount
            );
            pool.purchasedAmount += purchaseAmount;
        }
        pool.isClaimed[msg.sender] = true;
        pool.claimed += _amount;

        pool.claimToken.safeTransfer(msg.sender, _amount);

        emit Claimed(msg.sender, _amount);
    }

    function withdrawFunds(uint256 _pid) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        require(
            msg.sender == pool.beneficiary,
            "withdrawFunds: not a beneficiary"
        );
        require(
            pool.purchasedAmount > 0,
            "withdrawFunds: not enough tokens to withdraw"
        );

        pool.purchaseToken.transfer(msg.sender, pool.purchasedAmount);
        pool.purchasedAmount = 0;

        emit FundWithdrawed(msg.sender, pool.purchasedAmount);
    }

    function deposit(uint256 _pid, uint256 _amount) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        require(_amount >= pool.allocSize, "deposit: amount is too small");

        pool.deposited += _amount;
        pool.claimToken.transferFrom(msg.sender, address(this), _amount);

        emit Deposited(_pid, _amount);
    }

    function emergencyWithdraw(
        address _token,
        address _beneficiary,
        uint256 _amount
    ) public onlyOwner {
        require(
            _amount > 0,
            "emergencyWithdraw: Amount should be greater then 0"
        );

        IERC20Upgradeable(_token).transfer(_beneficiary, _amount);

        emit EmergencyWithdraw(_token, _beneficiary, _amount);
    }

    function pause() external override onlyOwner {
        super._pause();
    }

    function unpause() external override onlyOwner {
        super._unpause();
    }

    function verifyWhitelist(
        uint256 _pid,
        address _user,
        uint256 _amount,
        bytes32[] calldata _whitelistProof
    ) public view returns (bool) {
        PoolInfo storage pool = poolInfo[_pid];
        bytes32 leaf = keccak256(abi.encodePacked(_pid, _user, _amount));
        return _whitelistProof.verify(pool.whitelistRoot, leaf);
    }
}
