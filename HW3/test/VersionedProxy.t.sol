// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {VersionedProxy} from "../src/VersionedProxy.sol";
import {TokenV1} from "../src/TokenV1.sol";
import {TokenV2} from "../src/TokenV2.sol";
import {TokenV3} from "../src/TokenV3.sol";
import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

contract VersionedProxyTest is Test {
	VersionedProxy public proxy;
	TokenV1 public tokenV1Impl;
	TokenV2 public tokenV2Impl;
	TokenV3 public tokenV3Impl;

	address public owner;
	address public user;

	function setUp() public {
		owner = makeAddr("owner");
		user = makeAddr("user");

		tokenV1Impl = new TokenV1();
		tokenV2Impl = new TokenV2();
		tokenV3Impl = new TokenV3();

		vm.startPrank(owner);
		proxy = new VersionedProxy(address(tokenV1Impl));

		(bool success, ) = address(proxy).call(
			abi.encodeWithSelector(TokenV1.initialize.selector)
		);
		require(success, "Initialization failed");

		vm.stopPrank();
	}

	function test_InitialVersion() public view {
		assertEq(proxy.getVersionCount(), 1);
		assertEq(proxy.currentVersionIndex(), 0);
		assertEq(proxy.getCurrentImplementation(), address(tokenV1Impl));
	}

	function test_UpgradeToNewVersion() public {
		vm.startPrank(owner);
		proxy.upgradeTo(address(tokenV2Impl));
		vm.stopPrank();

		assertEq(proxy.getVersionCount(), 2);
		assertEq(proxy.currentVersionIndex(), 1);
		assertEq(proxy.getCurrentImplementation(), address(tokenV2Impl));
	}

	function test_RollbackToPreviousVersion() public {
		vm.prank(owner);
		proxy.upgradeTo(address(tokenV2Impl));

		vm.prank(owner);
		proxy.rollbackTo(0);

		assertEq(proxy.currentVersionIndex(), 0);
		assertEq(proxy.getCurrentImplementation(), address(tokenV1Impl));
	}

	function test_RollbackToSpecificVersion() public {
		vm.prank(owner);
		proxy.upgradeTo(address(tokenV2Impl));

		vm.prank(owner);
		proxy.upgradeTo(address(tokenV3Impl));

		vm.prank(owner);
		proxy.rollbackTo(1);

		assertEq(proxy.currentVersionIndex(), 1);
		assertEq(proxy.getCurrentImplementation(), address(tokenV2Impl));
	}

	function test_OnlyOwnerCanUpgrade() public {
		vm.expectRevert();
		vm.prank(user);
		proxy.upgradeTo(address(tokenV2Impl));
	}

	function test_OnlyOwnerCanRollback() public {
		vm.prank(owner);
		proxy.upgradeTo(address(tokenV2Impl));

		vm.expectRevert();
		vm.prank(user);
		proxy.rollbackTo(0);
	}

	function test_CannotRollbackToInvalidIndex() public {
		vm.prank(owner);
		vm.expectRevert();
		proxy.rollbackTo(999);
	}

	function test_TokenFunctionalityPreserved() public {
		ERC20Upgradeable token = ERC20Upgradeable(address(proxy));

		uint256 initialBalance = token.balanceOf(owner);
		assertGt(initialBalance, 0);
		console.log("Initial balance:", initialBalance);

		vm.prank(owner);
		proxy.upgradeTo(address(tokenV2Impl));

		assertEq(token.balanceOf(owner), initialBalance);

		vm.prank(owner);
		TokenV2(address(proxy)).burn(100);
		assertEq(token.balanceOf(owner), initialBalance - 100);

		vm.prank(owner);
		proxy.upgradeTo(address(tokenV3Impl));

		assertEq(token.balanceOf(owner), initialBalance - 100);

		vm.prank(owner);
		TokenV3(address(proxy)).pause();

		vm.expectRevert();
		vm.prank(user);
		token.transfer(user, 100);

		vm.prank(owner);
		TokenV3(address(proxy)).unpause();

		vm.prank(owner);
		bool success = token.transfer(user, 100);
		require(success, "Transfer failed");

		assertEq(token.balanceOf(user), 100);
	}
	
	function test_GetVersionAddress() public {
		vm.prank(owner);
		proxy.upgradeTo(address(tokenV2Impl));

		vm.prank(owner);
		proxy.upgradeTo(address(tokenV3Impl));

		assertEq(proxy.getVersionAddress(0), address(tokenV1Impl));
		assertEq(proxy.getVersionAddress(1), address(tokenV2Impl));
		assertEq(proxy.getVersionAddress(2), address(tokenV3Impl));
	}
}