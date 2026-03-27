// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {StakingManager} from "./StakingManager.sol";
import {VotingResultNFT} from "./VotingResultNFT.sol";

contract VotingContract is AccessControl, ReentrancyGuard, Pausable, IERC721Receiver {
	bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

	struct Voting {
		bytes32 id;
		uint256 deadline;
		uint256 votingPowerThreshold;
		string description;
		uint256 yesVotes;
		uint256 noVotes;
		bool finalized;
		bool passed;
		mapping(address => bool) hasVoted;
	}

	mapping(bytes32 => Voting) public votings;
	bytes32[] public votingIds;

	StakingManager public stakingManager;
	VotingResultNFT public resultNft;

	function onERC721Received(
		address,
		address,
		uint256,
		bytes calldata
	) external pure override returns (bytes4) {
		return this.onERC721Received.selector;
	}

	event VoteInitialized(bytes32 indexed votingId, string description, uint256 deadline, uint256 threshold);
	event VoteCast(bytes32 indexed votingId, address indexed voter, bool support, uint256 votingPower);
	event VoteFinalized(bytes32 indexed votingId, bool passed, uint256 yesVotes, uint256 noVotes, uint256 nftTokenId);

	constructor(address _stakingManager, address _resultNft) {
		_grantRole(ADMIN_ROLE, msg.sender);
		_grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
		stakingManager = StakingManager(_stakingManager);
		resultNft = VotingResultNFT(_resultNft);
	}

	function initializeVote(
		bytes32 votingId,
		uint256 deadline,
		uint256 votingPowerThreshold,
		string memory description
	) external onlyRole(ADMIN_ROLE) whenNotPaused {
		require(votings[votingId].deadline == 0, "Voting ID already exists");
		require(deadline > block.timestamp, "Deadline must be in future");

		Voting storage newVoting = votings[votingId];
		newVoting.id = votingId;
		newVoting.deadline = deadline;
		newVoting.votingPowerThreshold = votingPowerThreshold;
		newVoting.description = description;
		newVoting.yesVotes = 0;
		newVoting.noVotes = 0;
		newVoting.finalized = false;

		votingIds.push(votingId);

		emit VoteInitialized(votingId, description, deadline, votingPowerThreshold);
	}

	function castVote(bytes32 votingId, bool support) external nonReentrant whenNotPaused {
		Voting storage voting = votings[votingId];

		require(voting.deadline != 0, "Voting doesn't exist");
		require(!voting.finalized, "Voting already finalized");
		require(block.timestamp <= voting.deadline, "Voting deadline passed");
		require(!voting.hasVoted[msg.sender], "Already voted");

		uint256 votingPower = stakingManager.getCurrentVotingPower(msg.sender);
		require(votingPower > 0, "No voting power");

		voting.hasVoted[msg.sender] = true;

		if (support) {
			voting.yesVotes += votingPower;
		} else {
			voting.noVotes += votingPower;
		}

		emit VoteCast(votingId, msg.sender, support, votingPower);

		if (voting.yesVotes >= voting.votingPowerThreshold && !voting.finalized) {
			_finalizeVote(votingId);
		}
	}

	function finalizeVote(bytes32 votingId) external whenNotPaused {
		Voting storage voting = votings[votingId];
		
		require(voting.deadline != 0, "Voting doesn't exist");
		require(!voting.finalized, "Voting already finalized");
		require(block.timestamp > voting.deadline, "Voting deadline not reached");
		
		_finalizeVote(votingId);
	}

	function _finalizeVote(bytes32 votingId) internal {
		Voting storage voting = votings[votingId];
		require(!voting.finalized, "Already finalized");
		
		voting.finalized = true;
		bool passed = voting.yesVotes >= voting.votingPowerThreshold;
		voting.passed = passed;

		uint256 nftTokenId = resultNft.mintResultNft(
			votingId,
			voting.description,
			voting.yesVotes,
			voting.noVotes,
			voting.votingPowerThreshold,
			passed
		);

		emit VoteFinalized(votingId, passed, voting.yesVotes, voting.noVotes, nftTokenId);
	}

	function getVotingInfo(bytes32 votingId) external view returns (
		uint256 deadline,
		uint256 threshold,
		string memory description,
		uint256 yesVotes,
		uint256 noVotes,
		bool finalized,
		bool passed
	) {
		Voting storage voting = votings[votingId];
		return (
			voting.deadline,
			voting.votingPowerThreshold,
			voting.description,
			voting.yesVotes,
			voting.noVotes,
			voting.finalized,
			voting.passed
		);
	}

	function getAllVotings() external view returns (bytes32[] memory) {
		return votingIds;
	}

	function pause() external onlyRole(ADMIN_ROLE) {
		_pause();
	}

	function unpause() external onlyRole(ADMIN_ROLE) {
		_unpause();
	}
}