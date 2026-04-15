// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {DEXAggregator} from "../src/DEXAggregator.sol";

contract Deploy is Script {
	address constant UNISWAP_V2_FACTORY = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
	address constant UNISWAP_V2_ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
	address constant UNISWAP_V3_FACTORY = 0x1f98431C8ad98523631AE4a59F267346Ea31fAbe;
	address constant UNISWAP_V3_ROUTER = 0x68B3465833fb72B5a828cFB67D4C6F15C3B29139;

	DEXAggregator public aggregator;

	function setUp() public {}

	function run() public {
		uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
		address deployer = vm.addr(deployerPrivateKey);

		console.log("Deployer address:", deployer);
		console.log("Network: Sepolia Testnet");
		console.log("");

		vm.startBroadcast(deployerPrivateKey);

		console.log("Deploying DEX Aggregator");
		console.log("UniswapV2 Factory:", UNISWAP_V2_FACTORY);
		console.log("UniswapV2 Router:", UNISWAP_V2_ROUTER);
		console.log("UniswapV3 Factory:", UNISWAP_V3_FACTORY);
		console.log("UniswapV3 Router:", UNISWAP_V3_ROUTER);
		console.log("");

		aggregator =
			new DEXAggregator(deployer, UNISWAP_V2_FACTORY, UNISWAP_V2_ROUTER, UNISWAP_V3_FACTORY, UNISWAP_V3_ROUTER);

		console.log("DEX aggregator deployed at:", address(aggregator));
		console.log("");

		console.log("Setting protocol fee to 0.25%");
		aggregator.setProtocolFee(25);
		console.log("Protocol fee set");
		console.log("");

		console.log("Setting fee recipient to deployer address");
		aggregator.setFeeRecipient(deployer);
		console.log("Fee recipient set");
		console.log("");

		console.log("Enabling UniswapV3 fee tiers");
		aggregator.setSupportedV3Fee(500, true);
		aggregator.setSupportedV3Fee(3000, true);
		aggregator.setSupportedV3Fee(10000, true);
		console.log("Fee tiers enabled");
		console.log("");

		vm.stopBroadcast();

		console.log("DEX aggregator address:", address(aggregator));
		console.log("Owner:", deployer);
		console.log("Protocol fee: 0.25%");
		console.log("");
	}
}
