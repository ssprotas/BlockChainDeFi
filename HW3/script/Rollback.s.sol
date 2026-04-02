// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {VersionedProxy} from "../src/VersionedProxy.sol";

contract RollbackScript is Script {
	function run() external {
		uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
		address proxyAddress = vm.envAddress("PROXY_ADDRESS");
		uint256 versionIndex = vm.envUint("VERSION_INDEX");

		vm.startBroadcast(deployerPrivateKey);

		VersionedProxy proxy = VersionedProxy(payable(proxyAddress));

		console.log("Rolling back to version index:", versionIndex);
		proxy.rollbackTo(versionIndex);

		vm.stopBroadcast();

		_outputRollbackInfo(proxy, versionIndex);
	}
	
	function _outputRollbackInfo(VersionedProxy proxy, uint256 targetVersion) internal view {
		console.log("Rolled back successfully!");
		console.log("Current version index:", proxy.currentVersionIndex());
		console.log("Target version was:", targetVersion);
		console.log("Current implementation:", proxy.getCurrentImplementation());
	}
}