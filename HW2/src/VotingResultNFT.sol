// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract VotingResultNFT is ERC721, Ownable {
	uint256 private _nextTokenId;

	struct VoteResult {
		bytes32 votingId;
		string description;
		uint256 yesVotes;
		uint256 noVotes;
		uint256 threshold;
		bool passed;
		uint256 finalizedAt;
	}

	mapping(uint256 => VoteResult) public results;

	event NFTCreated(uint256 indexed tokenId, bytes32 indexed votingId, bool passed);

	constructor() ERC721("VotingResult", "VOTE") Ownable(msg.sender) {}
	
	function mintResultNft(
		bytes32 votingId,
		string memory description,
		uint256 yesVotes,
		uint256 noVotes,
		uint256 threshold,
		bool passed
	) external onlyOwner returns (uint256) {
		uint256 tokenId = _nextTokenId++;

		results[tokenId] = VoteResult({
			votingId: votingId,
			description: description,
			yesVotes: yesVotes,
			noVotes: noVotes,
			threshold: threshold,
			passed: passed,
			finalizedAt: block.timestamp
		});

		_safeMint(msg.sender, tokenId);

		emit NFTCreated(tokenId, votingId, passed);

		return tokenId;
	}

	function getResult(uint256 tokenId) external view returns (VoteResult memory) {
		return results[tokenId];
	}
}