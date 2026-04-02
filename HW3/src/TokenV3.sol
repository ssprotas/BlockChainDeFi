// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {ERC20PermitUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20PermitUpgradeable.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {IVersionable} from "./IVersionControl.sol";

contract TokenV3 is 
	Initializable, 
	ERC20Upgradeable, 
	ERC20PermitUpgradeable, 
	PausableUpgradeable,
	IVersionable
{
	uint256 private constant VERSION = 3;

	mapping(address => bool) public burners;

	event BurnerStatusChanged(address indexed account, bool status);
	event PauseToggled(bool isPaused);

	function initialize() public initializer {
		__ERC20_init("VersionedToken", "VTKN");
		__ERC20Permit_init("VersionedToken");
	}

	function mint(address to, uint256 amount) external {
		_mint(to, amount);
	}

	function burn(uint256 amount) external {
		_burn(msg.sender, amount);
	}

	function burnFrom(address account, uint256 amount) external {
		_spendAllowance(account, msg.sender, amount);
		_burn(account, amount);
	}

	function setBurner(address account, bool status) external {
		burners[account] = status;
		emit BurnerStatusChanged(account, status);
	}

	function pause() external {
		_pause();
		emit PauseToggled(true);
	}

	function unpause() external {
		_unpause();
		emit PauseToggled(false);
	}

	function _update(address from, address to, uint256 value) internal override whenNotPaused {
		super._update(from, to, value);
	}

	function getVersion() external pure returns (uint256) {
		return VERSION;
	}
}