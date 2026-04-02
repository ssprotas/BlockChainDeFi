// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {ERC20PermitUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20PermitUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {IVersionable} from "./IVersionControl.sol";

contract TokenV1 is Initializable, ERC20Upgradeable, ERC20PermitUpgradeable, IVersionable {
	uint256 private constant VERSION = 1;
	uint256 private constant INITIAL_SUPPLY = 1_000_000 * 10 ** 18;

	function initialize() public initializer {
		__ERC20_init("VersionedToken", "VTKN");
		__ERC20Permit_init("VersionedToken");
		_mint(msg.sender, INITIAL_SUPPLY);
	}

	function mint(address to, uint256 amount) external {
		_mint(to, amount);
	}

	function getVersion() external pure returns (uint256) {
		return VERSION;
	}
}