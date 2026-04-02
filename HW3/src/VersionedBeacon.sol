// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IBeacon} from "@openzeppelin/contracts/proxy/beacon/IBeacon.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IVersionControl} from "./IVersionControl.sol";

contract VersionedBeacon is IBeacon, IVersionControl, Ownable {
	error InvalidImplementation();
	error InvalidVersionIndex();

	address[] private _versionHistory;
	uint256 private _currentVersionIndex;

	event ImplementationUpgraded(
		address indexed previousImplementation,
		address indexed newImplementation,
		uint256 indexed versionIndex
	);
	event RolledBackToVersion(address indexed implementation, uint256 versionIndex);

	constructor(address initialImplementation) Ownable(msg.sender) {
		_validateImplementation(initialImplementation);
		_versionHistory.push(initialImplementation);
		_currentVersionIndex = 0;
		emit ImplementationUpgraded(address(0), initialImplementation, 0);
	}

	function upgradeTo(address newImplementation) external onlyOwner {
		address previousImpl = _versionHistory[_currentVersionIndex];
		_validateImplementation(newImplementation);

		_versionHistory.push(newImplementation);
		_currentVersionIndex = _versionHistory.length - 1;

		emit ImplementationUpgraded(previousImpl, newImplementation, _currentVersionIndex);
	}
	
	function rollbackTo(uint256 versionIndex) external onlyOwner {
		if (versionIndex >= _versionHistory.length) revert InvalidVersionIndex();

		address targetImplementation = _versionHistory[versionIndex];
		_validateImplementation(targetImplementation);

		_currentVersionIndex = versionIndex;
		emit RolledBackToVersion(targetImplementation, versionIndex);
	}

	function implementation() external view returns (address) {
		return _versionHistory[_currentVersionIndex];
	}

	function getVersionCount() external view returns (uint256) {
		return _versionHistory.length;
	}

	function getCurrentImplementation() external view returns (address) {
		return _versionHistory[_currentVersionIndex];
	}

	function getVersionAddress(uint256 index) external view returns (address) {
		if (index >= _versionHistory.length) revert InvalidVersionIndex();
		return _versionHistory[index];
	}

	function _validateImplementation(address impl) private view {
		if (impl == address(0) || impl.code.length == 0) revert InvalidImplementation();
	}
}