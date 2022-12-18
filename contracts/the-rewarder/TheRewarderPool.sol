// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./RewardToken.sol";
import "../DamnValuableToken.sol";
import "./AccountingToken.sol";

import "hardhat/console.sol";

/**
 * @title TheRewarderPool
 * @author Damn Vulnerable DeFi (https://damnvulnerabledefi.xyz)

 */
contract TheRewarderPool {
    // Minimum duration of each round of rewards in seconds
    uint256 private constant REWARDS_ROUND_MIN_DURATION = 5 days;

    uint256 public lastSnapshotIdForRewards;
    uint256 public lastRecordedSnapshotTimestamp;

    mapping(address => uint256) public lastRewardTimestamps;

    // Token deposited into the pool by users
    DamnValuableToken public immutable liquidityToken;

    // Token used for internal accounting and snapshots
    // Pegged 1:1 with the liquidity token
    AccountingToken public accToken;

    // Token in which rewards are issued
    // Given as a rewarded to stakers
    RewardToken public immutable rewardToken;

    // Track number of rounds
    uint256 public roundNumber;

    constructor(address tokenAddress) {
        // Assuming all three tokens have 18 decimals
        liquidityToken = DamnValuableToken(tokenAddress);
        accToken = new AccountingToken();
        rewardToken = new RewardToken();

        _recordSnapshot();
    }

    /**
     * @notice sender must have approved `amountToDeposit` liquidity tokens in advance
     */
    function deposit(uint256 amountToDeposit) external {
        require(amountToDeposit > 0, "Must deposit tokens");

        // Mint accounting token to depositor
        // This will take a checkpoint
        accToken.mint(msg.sender, amountToDeposit);

        // Rewards are distributed upon each deposit
        distributeRewards();

        require(
            liquidityToken.transferFrom(
                msg.sender,
                address(this),
                amountToDeposit
            )
        );
    }

    function withdraw(uint256 amountToWithdraw) external {
        accToken.burn(msg.sender, amountToWithdraw);
        require(liquidityToken.transfer(msg.sender, amountToWithdraw));
    }

    function distributeRewards() public returns (uint256) {
        uint256 rewards = 0;

        // If REWARDS_ROUND_MIN_DURATION has passed since last recorded snapshot
        if (isNewRewardsRound()) {
            // Take a snapshot
            _recordSnapshot();
        }

        uint256 totalDeposits = accToken.totalSupplyAt(
            lastSnapshotIdForRewards
        );

        // Gets balance of sender at latest snapshot
        uint256 amountDeposited = accToken.balanceOfAt(
            msg.sender,
            lastSnapshotIdForRewards
        );

        //
        if (amountDeposited > 0 && totalDeposits > 0) {
            rewards = (amountDeposited * 100 * 10 ** 18) / totalDeposits;

            if (rewards > 0 && !_hasRetrievedReward(msg.sender)) {
                rewardToken.mint(msg.sender, rewards);
                // update caller's last reward claim time
                lastRewardTimestamps[msg.sender] = block.timestamp;
            }
        }

        return rewards;
    }

    // Takses a new snapshot
    function _recordSnapshot() private {
        // Make a new snapshot and get its ID
        lastSnapshotIdForRewards = accToken.snapshot();
        // Record timestamp of snapshot
        lastRecordedSnapshotTimestamp = block.timestamp;
        // Increase round number
        roundNumber++;
    }

    function _hasRetrievedReward(address account) private view returns (bool) {
        return (lastRewardTimestamps[account] >=
            lastRecordedSnapshotTimestamp &&
            lastRewardTimestamps[account] <=
            lastRecordedSnapshotTimestamp + REWARDS_ROUND_MIN_DURATION);
    }

    function isNewRewardsRound() public view returns (bool) {
        return
            block.timestamp >=
            lastRecordedSnapshotTimestamp + REWARDS_ROUND_MIN_DURATION;
    }
}
