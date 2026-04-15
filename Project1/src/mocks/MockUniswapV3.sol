// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IUniswapV3Factory} from "../interfaces/IUniswapV3Factory.sol";
import {IUniswapV3Pool} from "../interfaces/IUniswapV3Pool.sol";

contract MockUniswapV3Pool is IUniswapV3Pool {
	address public override factory;
	address public override token0;
	address public override token1;
	uint24 public override fee;
	int24 public override tickSpacing;
	uint128 public override maxLiquidityPerTick;
	uint160 public sqrtPriceX96_;
	int24 public tick_;
	uint16 public observationIndex_;
	uint16 public observationCardinality_;
	uint16 public observationCardinalityNext_;
	uint8 public feeProtocol_;
	bool public unlocked_;

	constructor(address _factory, address _token0, address _token1, uint24 _fee, uint160 _sqrtPriceX96) {
		factory = _factory;
		token0 = _token0;
		token1 = _token1;
		fee = _fee;
		tickSpacing = 60;
		maxLiquidityPerTick = 1696311903449;
		sqrtPriceX96_ = _sqrtPriceX96;
		tick_ = 0;
		observationIndex_ = 0;
		observationCardinality_ = 1;
		observationCardinalityNext_ = 1;
		feeProtocol_ = 0;
		unlocked_ = true;
	}

	function slot0()
		external
		view
		override
		returns (
			uint160 sqrtPriceX96,
			int24 tick,
			uint16 observationIndex,
			uint16 observationCardinality,
			uint16 observationCardinalityNext,
			uint8 feeProtocol,
			bool unlocked
		)
	{
		return (
			sqrtPriceX96_,
			tick_,
			observationIndex_,
			observationCardinality_,
			observationCardinalityNext_,
			feeProtocol_,
			unlocked_
		);
	}

	function setSqrtPriceX96(uint160 _sqrtPriceX96) external {
		sqrtPriceX96_ = _sqrtPriceX96;
	}

	function liquidity() external view override returns (uint128) {
		return 1e18;
	}

	function feeGrowthGlobal0X128() external view override returns (uint256) {
		return 0;
	}

	function feeGrowthGlobal1X128() external view override returns (uint256) {
		return 0;
	}

	function protocolFees() external view override returns (uint128, uint128) {
		return (0, 0);
	}

	function ticks(int24)
		external
		view
		override
		returns (uint128, int128, uint256, uint256, int56, uint160, uint32, bool)
	{
		return (0, 0, 0, 0, 0, 0, 0, false);
	}

	function observe(uint32[] calldata secondsAgos)
		external
		view
		override
		returns (int56[] memory tickCumulatives, uint160[] memory secondsPerLiquidityCumulativeX128s)
	{
		tickCumulatives = new int56[](secondsAgos.length);
		secondsPerLiquidityCumulativeX128s = new uint160[](secondsAgos.length);
	}

	function swap(
		address recipient,
		bool zeroForOne,
		int256 amountSpecified,
		uint160 sqrtPriceLimitX96,
		bytes calldata data
	) external override returns (int256 amount0, int256 amount1) {
		return (0, 0);
	}
}

	contract MockUniswapV3Factory is IUniswapV3Factory {
		mapping(address => mapping(address => mapping(uint24 => address))) public override getPool;
		mapping(uint24 => int24) public override feeAmountTickSpacing;
		address public override owner;

		constructor() {
			owner = msg.sender;
			feeAmountTickSpacing[500] = 10;
			feeAmountTickSpacing[3000] = 60;
			feeAmountTickSpacing[10000] = 200;
		}

		function createPool(address tokenA, address tokenB, uint24 fee) external override returns (address pool) {
			require(tokenA != tokenB && tokenA != address(0) && tokenB != address(0), "Invalid tokens");

			(address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
			require(getPool[token0][token1][fee] == address(0), "Pool already exists");

			uint160 sqrtPriceX96 = 79228162514264337593543950336;

			pool = address(new MockUniswapV3Pool(address(this), token0, token1, fee, sqrtPriceX96));

			getPool[token0][token1][fee] = pool;
			getPool[token1][token0][fee] = pool;

			emit PoolCreated(token0, token1, fee, feeAmountTickSpacing[fee], pool);
		}

		function enableFeeAmount(uint24 fee, int24 tickSpacing) external override {
			feeAmountTickSpacing[fee] = tickSpacing;
			emit FeeAmountEnabled(fee, tickSpacing);
		}

		function setOwner(address _owner) external override {
			require(msg.sender == owner, "Only owner can set new owner");
			address oldOwner = owner;
			owner = _owner;
			emit OwnerChanged(oldOwner, _owner);
		}
	}
