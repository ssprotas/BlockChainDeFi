// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract RouteFinder {
	struct RouteInfo {
		address[] path;
		uint256 expectedOutput;
		uint256 priceImpact;
		uint8 dexType; // 1 for Uniswap V2, 2 for Uniswap V3
		uint24 v3Fee;
	}

	event RoutesCompared(
		address indexed tokenIn, address indexed tokenOut, uint256 v2Output, uint256 v3Output, address selectedDex
	);

	error NoRouteFound();
	error InvalidToken();

	function findBestDirectRoute(
		address tokenIn,
		address tokenOut,
		uint256 v2Output,
		uint256 v2Impact,
		uint256 v3Output,
		uint256 v3Impact,
		uint24 v3Fee
	) external pure returns (RouteInfo memory bestRoute) {
		if (v2Output == 0 && v3Output == 0) revert NoRouteFound();

		if (v3Output > v2Output) {
			bestRoute = RouteInfo({
				path: _buildPath(tokenIn, tokenOut),
				expectedOutput: v3Output,
				priceImpact: v3Impact,
				dexType: 2,
				v3Fee: v3Fee
			});
		} else {
			bestRoute = RouteInfo({
				path: _buildPath(tokenIn, tokenOut),
				expectedOutput: v2Output,
				priceImpact: v2Impact,
				dexType: 1,
				v3Fee: 0
			});
		}
	}

	function findBestMultiHopRoute(
		address tokenIn,
		address tokenOut,
		address[] calldata potentialIntermediates,
		uint256[] calldata hopOutputs,
		uint8[] calldata hopDexTypes
	) external pure returns (RouteInfo memory bestRoute) {
		uint256 bestOutput = 0;
		uint256 bestImpact = 10000;
		uint8 bestDexType = 0;
		address chosenIntermediate = address(0);

		for (uint256 i = 0; i < potentialIntermediates.length; i++) {
			if (hopOutputs[i] > bestOutput) {
				bestOutput = hopOutputs[i];
				bestDexType = hopDexTypes[i];
				chosenIntermediate = potentialIntermediates[i];
			}
		}

		if (bestOutput == 0) revert NoRouteFound();

		bestRoute = RouteInfo({
			path: _buildMultiHopPath(tokenIn, chosenIntermediate, tokenOut),
			expectedOutput: bestOutput,
			priceImpact: bestImpact,
			dexType: bestDexType,
			v3Fee: 0
		});
	}

	function _buildPath(address tokenIn, address tokenOut) internal pure returns (address[] memory) {
		address[] memory path = new address[](2);
		path[0] = tokenIn;
		path[1] = tokenOut;
		return path;
	}

	function _buildMultiHopPath(address tokenIn, address intermediate, address tokenOut)
		internal
		pure
		returns (address[] memory)
	{
		address[] memory path = new address[](3);
		path[0] = tokenIn;
		path[1] = intermediate;
		path[2] = tokenOut;
		return path;
	}

	function calculateOptimalSplit(uint256 totalAmount, uint256 v2Output, uint256 v3Output)
		external
		pure
		returns (uint256 amountToV2, uint256 amountToV3)
	{
		uint256 totalOutput = v2Output + v3Output;

		if (totalOutput == 0) {
			return (totalAmount / 2, totalAmount / 2);
		}

		amountToV2 = (totalAmount * v2Output) / totalOutput;
		amountToV3 = totalAmount - amountToV2;
	}
}
