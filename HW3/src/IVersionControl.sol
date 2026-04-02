// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IVersionable {
	function getVersion() external view returns (uint256);
}

interface IVersionControl {
	function upgradeTo(address newImplementation) external;
	function rollbackTo(uint256 versionIndex) external;
	function getVersionCount() external view returns (uint256);
	function getCurrentImplementation() external view returns (address);
	function getVersionAddress(uint256 index) external view returns (address);
}
