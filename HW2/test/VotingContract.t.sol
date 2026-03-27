// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {VVToken} from "../src/VVToken.sol";
import {StakingManager} from "../src/StakingManager.sol";
import {VotingResultNFT} from "../src/VotingResultNFT.sol";
import {VotingContract} from "../src/VotingContract.sol";

contract VotingContractTest is Test {
	VVToken public vvToken;
	StakingManager public stakingManager;
	VotingResultNFT public resultNft;
	VotingContract public votingContract;

	address public admin = address(0x1);
	address public voter1 = address(0x2);
	address public voter2 = address(0x3);

	function setUp() public {
		vm.startPrank(admin);

		vvToken = new VVToken();
		stakingManager = new StakingManager(address(vvToken));
		resultNft = new VotingResultNFT();

		votingContract = new VotingContract(address(stakingManager), address(resultNft));

		stakingManager.transferOwnership(address(votingContract));
		resultNft.transferOwnership(address(votingContract));

		vvToken.mint(voter1, 1000 * 10**18);
		vvToken.mint(voter2, 1000 * 10**18);

		vm.stopPrank();
	}

	function testStakeAndVote() public {
		vm.startPrank(voter1);
		vvToken.approve(address(stakingManager), 100 * 10**18);
		stakingManager.stake(100 * 10**18, 2);
		vm.stopPrank();

		vm.startPrank(voter2);
		vvToken.approve(address(stakingManager), 200 * 10**18);
		stakingManager.stake(200 * 10**18, 4);
		vm.stopPrank();

		vm.startPrank(admin);
		bytes32 votingId = keccak256(abi.encodePacked("Vote1"));
		uint256 deadline = block.timestamp + 7 days;
		uint256 threshold = 500 * 10**18;

		votingContract.initializeVote(votingId, deadline, threshold, "Should we increase it?");
		vm.stopPrank();

		vm.startPrank(voter1);
		votingContract.castVote(votingId, true);
		vm.stopPrank();

		vm.startPrank(voter2);
		votingContract.castVote(votingId, true);
		vm.stopPrank();

		(,,, uint256 yesVotes, , bool finalized, bool passed) = votingContract.getVotingInfo(votingId);

		assertTrue(finalized);
		assertTrue(passed);
		assertGt(yesVotes, 0);
	}

	function testUnstakeAfterExpiry() public {
		vm.startPrank(voter1);
		vvToken.approve(address(stakingManager), 100 * 10**18);
		stakingManager.stake(100 * 10**18, 1);

		vm.warp(block.timestamp + 8 days);

		stakingManager.unstake(0);

		uint256 votingPower = stakingManager.getCurrentVotingPower(voter1);
		assertEq(votingPower, 0);

		vm.stopPrank();
	}
}