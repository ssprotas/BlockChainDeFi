// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IUniswapV2Pair} from "./interfaces/IUniswapV2Pair.sol";
import {IUniswapV2Factory} from "./interfaces/IUniswapV2Factory.sol";
import {IUniswapV3Factory} from "./interfaces/IUniswapV3Factory.sol";
import {IUniswapV3Pool} from "./interfaces/IUniswapV3Pool.sol";

contract PriceFetcher {
	error PairDoesNotExist();
	error InvalidDecimals();
	error PoolDoesNotExist();

	uint256 private constant BASIS_POINTS = 10000;
	uint160 private constant MIN_SQRT_PRICE = 4295128739;
	uint160 private constant MAX_SQRT_PRICE = 1461446703485210835077038304875158528742;

	function getPriceFromUniswapV2(address factory, address tokenIn, address tokenOut, uint256 amountIn)
		external
		view
		returns (uint256 amountOut, uint256 priceImpact)
	{
		if (amountIn == 0) {
			return (0, BASIS_POINTS);
		}

		address pair = IUniswapV2Factory(factory).getPair(tokenIn, tokenOut);
		if (pair == address(0)) revert PairDoesNotExist();

		(uint112 reserve0, uint112 reserve1,) = IUniswapV2Pair(pair).getReserves();

		address token0 = IUniswapV2Pair(pair).token0();
		(uint112 reserveIn, uint112 reserveOut) = tokenIn == token0 ? (reserve0, reserve1) : (reserve1, reserve0);

		amountOut = _getAmountOut(amountIn, reserveIn, reserveOut);

		if (amountOut == 0) {
			priceImpact = BASIS_POINTS;
		} else {
			uint256 spotPrice = (uint256(reserveOut) * 1e18) / uint256(reserveIn);
			uint256 executionPrice = (amountOut * 1e18) / amountIn;
			if (spotPrice > 0 && spotPrice > executionPrice) {
				priceImpact = ((spotPrice - executionPrice) * BASIS_POINTS) / spotPrice;
			} else {
				priceImpact = 0;
			}
		}
	}

	function getPriceFromUniswapV3(address factory, address tokenIn, address tokenOut, uint24 fee, uint256 amountIn)
		external
		view
		returns (uint256 amountOut, uint256 priceImpact)
	{
		address pool = IUniswapV3Factory(factory).getPool(tokenIn, tokenOut, fee);
		if (pool == address(0)) revert PoolDoesNotExist();

		(uint160 sqrtPriceX96,,,,,,) = IUniswapV3Pool(pool).slot0();

		amountOut = _estimateV3OutputAmount(amountIn, sqrtPriceX96, tokenIn, tokenOut, fee);

		if (amountOut == 0) {
			priceImpact = BASIS_POINTS;
		} else {
			uint256 spotPrice = _calculateSpotPrice(sqrtPriceX96, tokenIn == IUniswapV3Pool(pool).token0());
			uint256 executionPrice = (amountOut * 1e18) / amountIn;
			if (spotPrice > 0 && spotPrice > executionPrice) {
				priceImpact = ((spotPrice - executionPrice) * BASIS_POINTS) / spotPrice;
			} else {
				priceImpact = 0;
			}
		}
	}

	function _getAmountOut(uint256 amountIn, uint112 reserveIn, uint112 reserveOut)
		internal
		pure
		returns (uint256 amountOut)
	{
		require(amountIn > 0, "Invalid input amount");
		require(reserveIn > 0 && reserveOut > 0, "Invalid reserves");

		uint256 amountInWithFee = amountIn * 997;
		uint256 numerator = amountInWithFee * reserveOut;
		uint256 denominator = (uint256(reserveIn) * 1000) + amountInWithFee;
		amountOut = numerator / denominator;
	}

	function _estimateV3OutputAmount(
		uint256 amountIn,
		uint160 sqrtPriceX96,
		address tokenIn,
		address tokenOut,
		uint24 fee
	) internal pure returns (uint256) {
		bool zeroForOne = tokenIn < tokenOut;

		uint256 feeMultiplier = (1000000 - (uint256(fee) * 1000)) / 1000000;

		uint256 baseOutput = _getBaseOutputFromPrice(amountIn, sqrtPriceX96, zeroForOne);
		return (baseOutput * feeMultiplier) / 1e18;
	}

	function _getBaseOutputFromPrice(uint256 amountIn, uint160 sqrtPriceX96, bool zeroForOne)
		internal
		pure
		returns (uint256)
	{
		uint256 sqrtPrice = uint256(sqrtPriceX96);
		if (zeroForOne) {
			return (amountIn * 1e12) / (sqrtPrice / 1e6);
		} else {
			return (amountIn * sqrtPrice) / 1e12;
		}
	}

	function _calculateSpotPrice(uint160 sqrtPriceX96, bool isToken0Reference) internal pure returns (uint256) {
		uint256 sqrtPrice = uint256(sqrtPriceX96);
		if (sqrtPrice > (1 << 128)) {
			uint256 ratioX96 = sqrtPrice >> 96;
			uint256 price = (ratioX96 * ratioX96) >> 96;
			
			return isToken0Reference ? price : (1e36 / (price + 1));
		} else {
			uint256 sqrtPriceSquared = sqrtPrice * sqrtPrice;
			uint256 price = sqrtPriceSquared / (1 << 192);
			
			return isToken0Reference ? price : 1e36 / (price + 1);
		}
	}
}
