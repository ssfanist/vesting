// SPDX-License-Identifier: MIT

pragma solidity ^0.7.4;

import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/cryptography/ECDSA.sol";
import "./interfaces/IRefundableDao.sol";

contract RefundableDao is IRefundableDao, AccessControl {
    using SafeMathUpgradeable for uint256;
    using SafeERC20 for IERC20;
    using ECDSA for bytes32;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE"); // Admin can addPool, set start timestamp, set price and withdraw collected Tokens
    bytes32 public constant QUOTE_SIGNER_ROLE = keccak256("QUOTE_SIGNER_ROLE"); // Quote signer can sign a quote to allow user purchase some tokens

    uint256 public id;

    mapping(uint256 => PoolInfo) poolInfo;

    modifier onlyAdmin() {
        require(hasRole(ADMIN_ROLE, msg.sender), "!admin");
        _;
    }

    constructor() {
        _setupRole(ADMIN_ROLE, msg.sender);
        _setupRole(QUOTE_SIGNER_ROLE, msg.sender);
    }

    // Owner can add Pool
    function addPool(
        uint256 _tokenPrice,
        address _token,
        address _teamToken,
        uint256 _startTime,
        uint256 _endTime,
        address _beneficiary
    ) external onlyAdmin {
        require(_tokenPrice > 0, "invalid token price");
        require(_teamToken != address(0), "token address cant be 0");
        require(
            _startTime < _endTime,
            "endTime should be greater than startTime"
        );
        require(_beneficiary != address(0), "token address cant be 0");

        PoolInfo storage pool = poolInfo[id];
        pool.tokenPrice = _tokenPrice;
        pool.token = _token;
        pool.teamToken = _teamToken;
        pool.startTime = _startTime;
        pool.endTime = _endTime;
        pool.beneficiary = _beneficiary;

        emit AddedPool(
            id,
            _tokenPrice,
            _token,
            _teamToken,
            _startTime,
            _endTime,
            _beneficiary
        );

        id += 1;
    }

    // Owner can set new startTime and endTime
    function setTimes(
        uint256 _poolId,
        uint256 _startTime,
        uint256 _endTime
    ) external onlyAdmin {
        require(
            _startTime < _endTime,
            "endTime should be greater than startTime"
        );

        PoolInfo storage pool = poolInfo[_poolId];
        pool.startTime = _startTime;
        pool.endTime = _endTime;

        emit SetTimes(_poolId, _startTime, _endTime);
    }

    // Owner can set new Price

    function setPrice(uint256 poolId, uint256 _tokenPrice) external onlyAdmin {
        require(_tokenPrice > 0, "invalid token price");

        PoolInfo storage pool = poolInfo[poolId];
        pool.tokenPrice = _tokenPrice;

        emit SetPrice(poolId, _tokenPrice);
    }

    // Owner can set new Beneficiary
    function setBeneficiaryAddress(uint256 poolId, address _beneficiary)
        external
        onlyAdmin
    {
        require(_beneficiary != address(0), "token address cant be 0");

        PoolInfo storage pool = poolInfo[poolId];
        pool.beneficiary = _beneficiary;

        emit SetBeneficiaryAddress(poolId, _beneficiary);
    }

    // Beneficiary can withdraw deposited funds

    function withdraw(uint256 poolId) external {
        PoolInfo storage pool = poolInfo[poolId];
        require(msg.sender == pool.beneficiary, "withdraw: not a beneficiary");

        require(
            IERC20(pool.token).transfer(msg.sender, pool.deposit),
            "withdraw: failed"
        );

        emit Withdrawed(poolId, msg.sender, pool.deposit);
    }

    // Beneficiary can withdraw unallocated team tokens

    function withdrawUnUsedTokens(uint256 poolId) external {
        PoolInfo storage pool = poolInfo[poolId];

        require(
            msg.sender == pool.beneficiary,
            "withdrawUnUsedTokens: not a beneficiary"
        );
        uint256 totalBalance = IERC20(pool.teamToken).balanceOf(address(this));
        uint256 usedAmount = pool.deposit * pool.tokenPrice;
        uint256 unUsedAmount;
        if (totalBalance >= usedAmount) {
            unUsedAmount = totalBalance - usedAmount;
        } else {
            usedAmount = totalBalance;
        }
        require(
            IERC20(pool.teamToken).transfer(msg.sender, unUsedAmount),
            "withdrawUnUsedTokens: failed"
        );

        emit WithdrawedUnUsedTokens(poolId, msg.sender, unUsedAmount);
    }

    function deposit(
        uint256 poolId,
        uint256 amount,
        uint256 quote,
        bytes calldata quoteSignature
    ) external {
        PoolInfo storage pool = poolInfo[poolId];
        require(block.timestamp <= pool.endTime, "deposit: already ended");
        require(block.timestamp >= pool.startTime, "deposit: not started yet");
        require(
            hasRole(
                QUOTE_SIGNER_ROLE,
                recoverSigner(_msgSender(), quote, quoteSignature)
            ),
            "!valid signature"
        );

        UserInfo storage user = pool.userInfo[msg.sender];

        require(
            IERC20(pool.token).transferFrom(msg.sender, address(this), amount),
            "deposit failed"
        );

        uint256 purchaseAmount = amount.mul(pool.tokenPrice).div(1e18);

        require(
            user.claimableAmount + purchaseAmount <= quote,
            "!enough quote"
        );

        user.claimableAmount += purchaseAmount;
        user.deposit += amount;

        pool.claimableAmount += purchaseAmount;
        pool.deposit += amount;

        emit Deposited(poolId, amount);
    }

    function refund(uint256 poolId) external {
        PoolInfo storage pool = poolInfo[poolId];

        require(
            block.timestamp.sub(24 * 3600) <= pool.endTime,
            "refund: cant refund after 24 hrs"
        );

        UserInfo storage user = pool.userInfo[msg.sender];

        require(
            IERC20(pool.token).transfer(msg.sender, user.deposit),
            "refund: refund failed"
        );

        pool.deposit = pool.deposit.sub(user.deposit);
        pool.claimableAmount = pool.claimableAmount.sub(user.claimableAmount);

        user.deposit = 0;
        user.claimableAmount = 0;

        emit Refunded(poolId, msg.sender, user.deposit);
    }

    function claim(uint256 poolId) external {
        PoolInfo storage pool = poolInfo[poolId];
        require(block.timestamp >= pool.endTime, "claim: not ended yet");

        UserInfo storage user = pool.userInfo[msg.sender];

        require(
            IERC20(pool.teamToken).transfer(msg.sender, user.claimableAmount),
            "claim: claim failed!"
        );

        pool.claimableAmount = pool.claimableAmount.sub(user.claimableAmount);

        user.claimableAmount = 0;
        user.deposit = 0;

        emit Claimed(poolId, msg.sender, user.claimableAmount);
    }

    function recoverSigner(
        address user,
        uint256 quote,
        bytes memory quoteSignature
    ) public pure returns (address) {
        bytes32 messageHash = keccak256(abi.encode(user, quote));
        bytes32 ethHash = messageHash.toEthSignedMessageHash();
        return ethHash.recover(quoteSignature);
    }

    function getBlockTimestamp() public view returns (uint256) {
        return block.timestamp;
    }
}
