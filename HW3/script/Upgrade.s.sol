// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {VersionedProxy} from "../src/VersionedProxy.sol";
import {TokenV2} from "../src/TokenV2.sol";
import {TokenV3} from "../src/TokenV3.sol";

contract UpgradeScript is Script {
	error InvalidUpgradeType();

	function run() external {
		uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
		address proxyAddress = vm.envAddress("PROXY_ADDRESS");
		string memory upgradeType = vm.envOr("UPGRADE_TYPE", string("v2"));

		vm.startBroadcast(deployerPrivateKey);

		VersionedProxy proxy = VersionedProxy(payable(proxyAddress));
		address newImplementation = _deployImplementation(upgradeType);

		console.log("Upgrading proxy...");
		proxy.upgradeTo(newImplementation);

		vm.stopBroadcast();

		_outputUpgradeInfo(proxy, newImplementation);
	}
	
	function _deployImplementation(string memory upgradeType) internal returns (address) {
		if (_compareStrings(upgradeType, "v2")) {
			console.log("Deploying TokenV2...");
			TokenV2 tokenV2 = new TokenV2();
			console.log("TokenV2 deployed at:", address(tokenV2));

			return address(tokenV2);
		} else if (_compareStrings(upgradeType, "v3")) {
			console.log("Deploying TokenV3...");
			TokenV3 tokenV3 = new TokenV3();
			console.log("TokenV3 deployed at:", address(tokenV3));

			return address(tokenV3);
		}

		revert InvalidUpgradeType();
	}

	function _outputUpgradeInfo(VersionedProxy proxy, address newImpl) internal view {
		console.log("Upgraded to version index:", proxy.currentVersionIndex());
		console.log("Current implementation:", newImpl);
	}

	function _compareStrings(string memory a, string memory b) internal pure returns (bool) {
		return keccak256(bytes(a)) == keccak256(bytes(b));
	}
}