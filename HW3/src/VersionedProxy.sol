// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Proxy} from "@openzeppelin/contracts/proxy/Proxy.sol";
import {IVersionControl} from "./IVersionControl.sol";

contract VersionedProxy is Proxy, IVersionControl {
	error UnauthorizedAccess();
	error InvalidImplementation();
	error InvalidVersionIndex();

	address[] private _versionHistory;
	uint256 private _currentVersionIndex;
	address private _owner;

	event ImplementationUpgraded(
		address indexed previousImplementation,
		address indexed newImplementation,
		uint256 indexed versionIndex
	);
	event RolledBackToVersion(address indexed implementation, uint256 versionIndex);
	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

	function _onlyOwner() internal view {
		if (msg.sender != _owner) revert UnauthorizedAccess();
	}

	modifier onlyOwner() {
		_onlyOwner();
		_;
	}

	constructor(address initialImplementation) {
		_validateImplementation(initialImplementation);
		_owner = msg.sender;
		_versionHistory.push(initialImplementation);
		_currentVersionIndex = 0;
		emit ImplementationUpgraded(address(0), initialImplementation, 0);
	}

	receive() external payable {}

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

	function transferOwnership(address newOwner) external onlyOwner {
		if (newOwner == address(0)) revert InvalidImplementation();

		address previousOwner = _owner;
		_owner = newOwner;

		emit OwnershipTransferred(previousOwner, newOwner);
	}

	function getVersionCount() external view returns (uint256) {
		return _versionHistory.length;
	}

	function getVersionAddress(uint256 index) external view returns (address) {
		if (index >= _versionHistory.length) revert InvalidVersionIndex();

		return _versionHistory[index];
	}

	function getCurrentImplementation() external view returns (address) {
		return _versionHistory[_currentVersionIndex];
	}

	function currentVersionIndex() external view returns (uint256) {
		return _currentVersionIndex;
	}

	function owner() external view returns (address) {
		return _owner;
	}

	function _implementation() internal view override returns (address) {
		return _versionHistory[_currentVersionIndex];
	}

	function _validateImplementation(address impl) private view {
		if (impl == address(0) || impl.code.length == 0) revert InvalidImplementation();
	}
}