// SPDX-License-Identifier: MIT

pragma solidity ^0.7.4;

import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "./interfaces/IWalletLocking.sol";

contract WalletLocking is IWalletLocking {
    using SafeMathUpgradeable for uint256;
    using SafeERC20 for IERC20;

    uint256 public depositId;
    mapping(uint256 => DepositInfo) public depositInfo;
    mapping(uint256 => mapping(address => uint256)) public allocInfo;
    mapping(uint256 => mapping(address => uint256)) public withdrawInfo;

    function lock(
        address _token,
        uint256 _lock,
        uint256[] memory _percentages,
        uint256[] memory _vestings,
        address[] memory _beneficiaries,
        uint256[] memory _allocAmounts
    ) external override {
        require(_token != address(0), "deposit: token address can't be 0");
        require(_vestings.length == _percentages.length, "deposit: Input arrary lengths mismatch");
        require(_beneficiaries.length == _allocAmounts.length, "deposit: Input arrary lengths mismatch");

        DepositInfo storage _depositInfo = depositInfo[depositId];
        uint256 totalPercentages;
        for (uint256 i = 0; i < _percentages.length; i++) {
            totalPercentages = totalPercentages.add(_percentages[i]);
        }
        require(totalPercentages == 100, "deposit: sum of percentages should be 100");

        uint256 totalAmount;
        for (uint256 i = 0; i < _allocAmounts.length; i++) {
            totalAmount = totalAmount + _allocAmounts[i];
            allocInfo[depositId][_beneficiaries[i]] = _allocAmounts[i];
        }

        require(totalAmount > 0, "deposit: must lock more than 0 tokens");
        require(IERC20(_token).balanceOf(address(this)) >= totalAmount, "deposit: Insufficient Balance");

        _depositInfo._token = _token;
        _depositInfo.lock = _lock;
        _depositInfo._percentages = _percentages;
        _depositInfo.vestings = _vestings;
        _depositInfo.depositTime = block.timestamp;
        _depositInfo.totalAmount = totalAmount;

        depositId = depositId + 1;

        IERC20 token = IERC20(_token);
        token.safeTransferFrom(address(msg.sender), address(this), totalAmount);

        emit Lock(depositId - 1, _token, _lock, _percentages, _vestings, _beneficiaries, _allocAmounts);
    }

    function withdraw(uint256 _depositId) external override {
        uint256 vestableAmount = _calcVestableAmount(_depositId);

        require(
            vestableAmount > withdrawInfo[_depositId][address(msg.sender)],
            "withdraw: no tokens to withdraw at the moment"
        );

        DepositInfo storage _depositInfo = depositInfo[_depositId];

        IERC20 token = IERC20(_depositInfo._token);
        uint256 transferAmount = vestableAmount.sub(withdrawInfo[_depositId][address(msg.sender)]);

        withdrawInfo[_depositId][address(msg.sender)] = withdrawInfo[_depositId][address(msg.sender)].add(
            transferAmount
        );
        token.safeTransfer(address(msg.sender), transferAmount);

        emit Withdraw(depositId, transferAmount, address(msg.sender));
    }

    function _calcVestableAmount(uint256 _depositId) public view returns (uint256) {
        if (_depositId >= depositId) {
            return 0;
        }

        DepositInfo storage _depositInfo = depositInfo[_depositId];

        uint256 currentVesting = _depositInfo.depositTime + _depositInfo.lock;

        if (block.timestamp <= currentVesting) {
            return 0;
        }

        uint256 currentVestingIndex;
        uint256[] memory vestings = _depositInfo.vestings;
        for (uint256 i = 0; i < vestings.length; i++) {
            currentVestingIndex = i;
            if (currentVesting.add(vestings[i]) < block.timestamp) {
                currentVesting = currentVesting.add(vestings[i]);
            } else {
                break;
            }
        }

        uint256 vestableAmount;
        uint256 allocAmount = allocInfo[_depositId][address(msg.sender)];
        for (uint256 i = 0; i < currentVestingIndex; i++) {
            vestableAmount = vestableAmount + allocAmount.mul(_depositInfo._percentages[i]).div(100);
        }
        uint256 timePassed = block.timestamp.sub(currentVesting);
        if (timePassed > _depositInfo.vestings[currentVestingIndex]) {
            timePassed = _depositInfo.vestings[currentVestingIndex];
        }
        vestableAmount =
            vestableAmount +
            timePassed
                .mul(allocAmount)
                .mul(_depositInfo._percentages[currentVestingIndex])
                .div(_depositInfo.vestings[currentVestingIndex])
                .div(100);
        return vestableAmount;
    }
}
