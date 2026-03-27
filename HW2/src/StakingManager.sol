// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract StakingManager is Ownable, ReentrancyGuard {
	IERC20 public vvToken;

	struct Stake {
		uint256 amount;
		uint256 initialDuration;
		uint256 expiryTime;
	}

	mapping(address => Stake[]) public stakes;
	mapping(address => uint256) public totalVotingPower;

	event Staked(address indexed user, uint256 amount, uint256 duration);
	event Unstaked(address indexed user, uint256 stakeIndex, uint256 amount);

	constructor(address _vvToken) Ownable(msg.sender) {
		vvToken = IERC20(_vvToken);
	}

	function stake(uint256 amount, uint256 durationWeeks) external nonReentrant {
		require(amount > 0, "Cannot stake 0");
		require(durationWeeks >= 1 && durationWeeks <= 4, "Duration must be 1-4 weeks");

		uint256 durationSec = durationWeeks * 1 weeks;
		uint256 expiry = block.timestamp + durationSec;

		stakes[msg.sender].push(Stake({
			amount: amount,
			initialDuration: durationSec,
			expiryTime: expiry
		}));

		bool success = vvToken.transferFrom(msg.sender, address(this), amount);
		require(success, "TransferFrom failed");

		_updateVotingPower(msg.sender);

		emit Staked(msg.sender, amount, durationWeeks);
	}

	function _updateVotingPower(address user) internal {
		uint256 totalVp = 0;
		for (uint256 i = 0; i < stakes[user].length; i++) {
			Stake storage stakeInfo = stakes[user][i];
			if (stakeInfo.expiryTime > block.timestamp) {
				uint256 remainingTime = stakeInfo.expiryTime - block.timestamp;
				uint256 remainingWeeks = remainingTime / 1 weeks;
				totalVp += (remainingWeeks ** 2) * stakeInfo.amount;
			}
		}
		totalVotingPower[user] = totalVp;
	}

	function getCurrentVotingPower(address user) external view returns (uint256) {
		uint256 totalVp = 0;
		for (uint256 i = 0; i < stakes[user].length; i++) {
			Stake storage stakeInfo = stakes[user][i];
			if (stakeInfo.expiryTime > block.timestamp) {
				uint256 remainingTime = stakeInfo.expiryTime - block.timestamp;
				uint256 remainingWeeks = remainingTime / 1 weeks;
				totalVp += (remainingWeeks ** 2) * stakeInfo.amount;
			}
		}
		return totalVp;
	}

	function unstake(uint256 stakeIndex) external nonReentrant {
		require(stakeIndex < stakes[msg.sender].length, "Invalid stake index");
		Stake storage stakeInfo = stakes[msg.sender][stakeIndex];
		require(stakeInfo.expiryTime <= block.timestamp, "Stake not expired yet");

		uint256 amount = stakeInfo.amount;

		stakes[msg.sender][stakeIndex] = stakes[msg.sender][stakes[msg.sender].length - 1];
		stakes[msg.sender].pop();

		_updateVotingPower(msg.sender);

		bool success = vvToken.transfer(msg.sender, amount);
		require(success, "Transfer failed");

		emit Unstaked(msg.sender, stakeIndex, amount);
	}
}