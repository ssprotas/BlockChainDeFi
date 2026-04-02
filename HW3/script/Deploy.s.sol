// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {VersionedProxy} from "../src/VersionedProxy.sol";
import {VersionedBeacon} from "../src/VersionedBeacon.sol";
import {TokenV1} from "../src/TokenV1.sol";
import {BeaconProxy} from "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";

contract DeployScript is Script {
	function run() external {
		uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
		vm.startBroadcast(deployerPrivateKey);

		TokenV1 tokenV1 = _deployTokenV1();
		VersionedProxy proxy = _deployVersionedProxy(address(tokenV1));
		VersionedBeacon beacon = _deployVersionedBeacon(address(tokenV1));
		BeaconProxy beaconProxy = _deployBeaconProxy(address(beacon));

		vm.stopBroadcast();

		_outputAddresses(address(tokenV1), address(proxy), address(beacon), address(beaconProxy));
	}

	function _deployTokenV1() internal returns (TokenV1) {
		console.log("Deploying TokenV1...");
		TokenV1 token = new TokenV1();
		console.log("TokenV1 deployed at:", address(token));

		return token;
	}

	function _deployVersionedProxy(address implementation) internal returns (VersionedProxy) {
		console.log("Deploying VersionedProxy...");
		VersionedProxy proxy = new VersionedProxy(implementation);
		console.log("VersionedProxy deployed at:", address(proxy));

		return proxy;
	}

	function _deployVersionedBeacon(address implementation) internal returns (VersionedBeacon) {
		console.log("Deploying VersionedBeacon...");
		VersionedBeacon beacon = new VersionedBeacon(implementation);
		console.log("VersionedBeacon deployed at:", address(beacon));

		return beacon;
	}

	function _deployBeaconProxy(address beacon) internal returns (BeaconProxy) {
		console.log("Deploying BeaconProxy...");

		BeaconProxy beaconProxy = new BeaconProxy(
			beacon,
			abi.encodeWithSelector(TokenV1.initialize.selector)
		);

		console.log("BeaconProxy deployed at:", address(beaconProxy));

		return beaconProxy;
	}

	function _outputAddresses(
		address tokenV1,
		address proxy,
		address beacon,
		address beaconProxy
	) internal pure {
		console.log("\n=== Deployment Addresses ===");
		console.log("TokenV1:", tokenV1);
		console.log("VersionedProxy:", proxy);
		console.log("VersionedBeacon:", beacon);
		console.log("BeaconProxy:", beaconProxy);
	}
}