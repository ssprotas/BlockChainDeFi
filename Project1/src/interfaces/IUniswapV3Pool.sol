// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IUniswapV3Pool {
	function factory() external view returns (address);

	function token0() external view returns (address);

	function token1() external view returns (address);

	function fee() external view returns (uint24);

	function tickSpacing() external view returns (int24);

	function maxLiquidityPerTick() external view returns (uint128);

	function slot0()
		external
		view
		returns (
			uint160 sqrtPriceX96,
			int24 tick,
			uint16 observationIndex,
			uint16 observationCardinality,
			uint16 observationCardinalityNext,
			uint8 feeProtocol,
			bool unlocked
		);

	function feeGrowthGlobal0X128() external view returns (uint256);

	function feeGrowthGlobal1X128() external view returns (uint256);

	function protocolFees() external view returns (uint128 token0, uint128 token1);

	function liquidity() external view returns (uint128);

	function ticks(int24 tick)
		external
		view
		returns (
			uint128 liquidityGross,
			int128 liquidityNet,
			uint256 feeGrowthOutside0X128,
			uint256 feeGrowthOutside1X128,
			int56 tickCumulativeOutside,
			uint160 secondsPerLiquidityOutsideX128,
			uint32 secondsOutside,
			bool initialized
		);

	function observe(uint32[] calldata secondsAgos)
		external
		view
		returns (int56[] memory tickCumulatives, uint160[] memory secondsPerLiquidityCumulativeX128s);

	function swap(
		address recipient,
		bool zeroForOne,
		int256 amountSpecified,
		uint160 sqrtPriceLimitX96,
		bytes calldata data
	) external returns (int256 amount0, int256 amount1);
}
