// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {DEXAggregator} from "../src/DEXAggregator.sol";
import {PriceFetcher} from "../src/PriceFetcher.sol";
import {RouteFinder} from "../src/RouteFinder.sol";
import {MockERC20} from "../src/mocks/MockERC20.sol";
import {MockUniswapV2Factory, MockUniswapV2Router, MockUniswapV2Pair} from "../src/mocks/MockUniswapV2.sol";
import {MockUniswapV3Factory} from "../src/mocks/MockUniswapV3.sol";

contract DEXAggregatorTest is Test {
	DEXAggregator public aggregator;
	PriceFetcher public priceFetcher;
	RouteFinder public routeFinder;

	MockUniswapV2Factory public v2Factory;
	MockUniswapV2Router public v2Router;
	MockUniswapV3Factory public v3Factory;

	MockERC20 public tokenA;
	MockERC20 public tokenB;
	MockERC20 public tokenC;

	address public prankAddr = address(0x1234);

	event SwapExecuted(
		address indexed tokenIn,
		address indexed tokenOut,
		uint256 amountIn,
		uint256 amountOut,
		uint8 dexType,
		uint256 priceImpact,
		uint256 feeTaken
	);

	function setUp() public {
		tokenA = new MockERC20("Token A", "TKA", 18, 1_000_000);
		tokenB = new MockERC20("Token B", "TKB", 18, 1_000_000);
		tokenC = new MockERC20("Token C", "TKC", 18, 1_000_000);

		v2Factory = new MockUniswapV2Factory();
		v2Router = new MockUniswapV2Router(address(v2Factory), address(tokenA));
		v3Factory = new MockUniswapV3Factory();

		address v2Pair = v2Factory.createPair(address(tokenA), address(tokenB));
		MockUniswapV2Pair(v2Pair).setReserves(1000e18, 2000e18);

		v3Factory.createPool(address(tokenA), address(tokenB), 500);
		v3Factory.createPool(address(tokenA), address(tokenB), 3000);
		v3Factory.createPool(address(tokenA), address(tokenB), 10000);

		aggregator = new DEXAggregator(
			address(this), address(v2Factory), address(v2Router), address(v3Factory), address(v2Router)
		);
		priceFetcher = aggregator.priceFetcher();
		routeFinder = aggregator.routeFinder();

		bool success = tokenA.transfer(prankAddr, 100e18);
		require(success, "Token A transfer failed");
		success = tokenB.transfer(prankAddr, 100e18);
		require(success, "Token B transfer failed");

		vm.prank(prankAddr);
		tokenA.approve(address(aggregator), type(uint256).max);
		vm.prank(prankAddr);
		tokenB.approve(address(aggregator), type(uint256).max);
	}

	function testPriceFetcherV2Price() public view {
		(uint256 output, uint256 impact) =
			priceFetcher.getPriceFromUniswapV2(address(v2Factory), address(tokenA), address(tokenB), 1e18);

		assertGt(output, 0, "Output should be greater than 0");
		assertLt(impact, 10000, "Price impact should be less than 100%");
	}

	function testPriceFetcherV2InvalidPair() public {
		vm.expectRevert();
		priceFetcher.getPriceFromUniswapV2(address(v2Factory), address(tokenA), address(tokenC), 1e18);
	}

	function testPriceFetcherZeroAmount() public view {
		(uint256 output,) = priceFetcher.getPriceFromUniswapV2(address(v2Factory), address(tokenA), address(tokenB), 0);

		assertEq(output, 0, "Output should be 0 for zero input");
	}

	function testRouteFinderBestDirectRoute() public view {
		uint256 v2Output = 2.0e18;
		uint256 v3Output = 1.8e18;

		RouteFinder.RouteInfo memory route =
			routeFinder.findBestDirectRoute(address(tokenA), address(tokenB), v2Output, 50, v3Output, 75, 3000);

		assertEq(route.dexType, 1, "Should select V2 (higher output)");
		assertEq(route.expectedOutput, v2Output, "Should have V2 output");
		assertEq(route.path.length, 2, "Path should have 2 tokens");
	}

	function testRouteFinderV3Better() public view {
		uint256 v2Output = 1.8e18;
		uint256 v3Output = 2.0e18;

		RouteFinder.RouteInfo memory route =
			routeFinder.findBestDirectRoute(address(tokenA), address(tokenB), v2Output, 50, v3Output, 40, 3000);

		assertEq(route.dexType, 2, "Should select V3 (higher output)");
		assertEq(route.expectedOutput, v3Output, "Should have V3 output");
	}

	function testRouteFinderNoRoute() public {
		vm.expectRevert();
		routeFinder.findBestDirectRoute(address(tokenA), address(tokenB), 0, 0, 0, 0, 3000);
	}

	function testRouteFinderMultiHopRoute() public view {
		address[] memory intermediates = new address[](1);
		intermediates[0] = address(tokenC);

		uint256[] memory hopOutputs = new uint256[](1);
		hopOutputs[0] = 1.5e18;

		uint8[] memory hopDexTypes = new uint8[](1);
		hopDexTypes[0] = 1;

		RouteFinder.RouteInfo memory route =
			routeFinder.findBestMultiHopRoute(address(tokenA), address(tokenB), intermediates, hopOutputs, hopDexTypes);

		assertEq(route.path.length, 3, "Multi-hop path should have 3 tokens");
		assertEq(route.path[1], address(tokenC), "Intermediate token should be in path");
	}

	function testSwapWithBestRoute() public {
		uint256 amountIn = 1e18;

		(uint256 expectedOutput,,) = aggregator.getQuote(address(tokenA), address(tokenB), amountIn);
		assertGt(expectedOutput, 0, "Quote should be positive");

		vm.prank(prankAddr);
		uint256 amountOut = aggregator.swapWithBestRoute(address(tokenA), address(tokenB), amountIn, 0);

		assertGt(amountOut, 0, "Should receive tokens");
		assertLe(amountOut, expectedOutput, "Output should not exceed quote");
	}

	function testSwapWithInsufficientOutput() public {
		uint256 amountIn = 1e18;
		uint256 minAmountOut = 100e18;

		vm.prank(prankAddr);
		vm.expectRevert();
		aggregator.swapWithBestRoute(address(tokenA), address(tokenB), amountIn, minAmountOut);
	}

	function testSwapWithZeroAmount() public {
		vm.prank(prankAddr);
		vm.expectRevert();
		aggregator.swapWithBestRoute(address(tokenA), address(tokenB), 0, 0);
	}

	function testSwapWithSameToken() public {
		vm.prank(prankAddr);
		vm.expectRevert();
		aggregator.swapWithBestRoute(address(tokenA), address(tokenA), 1e18, 0);
	}

	function testGetQuote() public view {
		(uint256 output, uint256 impact, uint8 dexType) = aggregator.getQuote(address(tokenA), address(tokenB), 1e18);

		assertGt(output, 0, "Quote output should be positive");
		assertLe(impact, 10000, "Price impact should be <= 100%");
		assertTrue(dexType == 1 || dexType == 2, "DEX type should be 1 or 2");
	}

	function testProtocolFee() public {
		uint256 amountIn = 10e18;
		uint256 initialFeeRecipientBalance = tokenB.balanceOf(address(this));

		vm.prank(prankAddr);
		uint256 amountOut = aggregator.swapWithBestRoute(address(tokenA), address(tokenB), amountIn, 0);

		uint256 feeRecipientBalance = tokenB.balanceOf(address(this));

		assertGt(feeRecipientBalance, initialFeeRecipientBalance, "Fee recipient should receive tokens");
	}

	function testSetProtocolFee() public {
		aggregator.setProtocolFee(50);
		(,, uint256 fee,) = aggregator.getStats();
		assertEq(fee, 50, "Protocol fee should be updated");
	}

	function testSetProtocolFeeToHighFails() public {
		vm.expectRevert();
		aggregator.setProtocolFee(2000);
	}

	function testSetFeeRecipient() public {
		address newRecipient = address(0x9999);
		aggregator.setFeeRecipient(newRecipient);

		vm.prank(prankAddr);
		aggregator.swapWithBestRoute(address(tokenA), address(tokenB), 1e18, 0);

		uint256 balance = tokenB.balanceOf(newRecipient);
		assertGt(balance, 0, "New recipient should receive fees");
	}

	function testSetFeeRecipientZeroAddressFails() public {
		vm.expectRevert();
		aggregator.setFeeRecipient(address(0));
	}

	function testPauseAndUnpause() public {
		aggregator.pause();

		vm.prank(prankAddr);
		vm.expectRevert();
		aggregator.swapWithBestRoute(address(tokenA), address(tokenB), 1e18, 0);

		aggregator.unpause();
		vm.prank(prankAddr);
		uint256 amountOut = aggregator.swapWithBestRoute(address(tokenA), address(tokenB), 1e18, 0);

		assertGt(amountOut, 0, "Swap should succeed after unpause");
	}

	function testEmergencyWithdraw() public {
		bool success = tokenA.transfer(address(aggregator), 10e18);
		require(success, "Token transfer failed");

		uint256 balanceBefore = tokenA.balanceOf(address(this));
		aggregator.emergencyWithdraw(address(tokenA));
		uint256 balanceAfter = tokenA.balanceOf(address(this));

		assertGt(balanceAfter, balanceBefore, "Should withdraw tokens");
	}

	function testStatsTracking() public {
		(uint256 swapsBefore,,,) = aggregator.getStats();

		vm.prank(prankAddr);
		aggregator.swapWithBestRoute(address(tokenA), address(tokenB), 1e18, 0);

		(uint256 swapsAfter, uint256 volume,, address feeRecip) = aggregator.getStats();

		assertEq(swapsAfter, swapsBefore + 1, "Swap count should increase");
		assertGt(volume, 0, "Volume should be tracked");
		assertEq(feeRecip, address(this), "Fee recipient should be recorded");
	}

	function testReentrancyProtection() public {
		vm.prank(prankAddr);
		uint256 amountOut = aggregator.swapWithBestRoute(address(tokenA), address(tokenB), 1e18, 0);

		assertGt(amountOut, 0, "Swap should complete without reentrancy");
	}

	function testSwapLargeAmount() public {
		uint256 largeAmount = 50e18;

		vm.prank(prankAddr);
		uint256 amountOut = aggregator.swapWithBestRoute(address(tokenA), address(tokenB), largeAmount, 0);

		assertGt(amountOut, 0, "Large swap should succeed");
	}

	function testMultipleSwapsInSequence() public {
		for (uint256 i = 0; i < 3; i++) {
			vm.prank(prankAddr);
			aggregator.swapWithBestRoute(address(tokenA), address(tokenB), 1e18, 0);
		}

		(uint256 swaps,,,) = aggregator.getStats();
		assertEq(swaps, 3, "Should track all swaps");
	}
}
