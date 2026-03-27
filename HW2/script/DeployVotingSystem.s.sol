// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {VVToken} from "../src/VVToken.sol";
import {StakingManager} from "../src/StakingManager.sol";
import {VotingResultNFT} from "../src/VotingResultNFT.sol";
import {VotingContract} from "../src/VotingContract.sol";

contract DeployVotingSystem is Script {
	function run() external {
		uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

		vm.startBroadcast(deployerPrivateKey);

		VVToken vvToken = new VVToken();
		console.log("VVToken deployed at:", address(vvToken));

		StakingManager stakingManager = new StakingManager(address(vvToken));
		console.log("StakingManager deployed at:", address(stakingManager));

		VotingResultNFT resultNft = new VotingResultNFT();
		console.log("VotingResultNFT deployed at:", address(resultNft));

		VotingContract votingContract = new VotingContract(
			address(stakingManager),
			address(resultNft)
		);
		console.log("VotingContract deployed at:", address(votingContract));

		vm.stopBroadcast();
	}
}