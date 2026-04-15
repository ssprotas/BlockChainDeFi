// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IUniswapV2Factory} from "../interfaces/IUniswapV2Factory.sol";
import {IUniswapV2Router} from "../interfaces/IUniswapV2Router.sol";
import {MockERC20} from "./MockERC20.sol";

contract MockUniswapV2Pair {
	address public token0;
	address public token1;
	uint112 public reserve0;
	uint112 public reserve1;
	uint32 public blockTimestampLast;

	constructor(address _token0, address _token1) {
		token0 = _token0;
		token1 = _token1;
	}

	function setReserves(uint112 _reserve0, uint112 _reserve1) public {
		reserve0 = _reserve0;
		reserve1 = _reserve1;
		blockTimestampLast = uint32(block.timestamp);
	}

	function getReserves() public view returns (uint112, uint112, uint32) {
		return (reserve0, reserve1, blockTimestampLast);
	}

	function swap(uint256 amount0Out, uint256 amount1Out, address to, bytes calldata) public {
		bool success;
		if (amount0Out > 0) {
			success = MockERC20(token0).transfer(to, amount0Out);
			require(success, "Token transfer failed");
		}
		if (amount1Out > 0) {
			success = MockERC20(token1).transfer(to, amount1Out);
			require(success, "Token transfer failed");
		}
	}
}

contract MockUniswapV2Factory is IUniswapV2Factory {
	mapping(address => mapping(address => address)) public getPair;
	address[] public allPairs;

	function createPair(address tokenA, address tokenB) external override returns (address pair) {
		require(tokenA != tokenB && tokenA != address(0) && tokenB != address(0), "Invalid tokens");

		(address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);

		pair = address(new MockUniswapV2Pair(token0, token1));

		getPair[token0][token1] = pair;
		getPair[token1][token0] = pair;
		allPairs.push(pair);

		emit PairCreated(token0, token1, pair, allPairs.length);
	}

	function allPairsLength() external view override returns (uint256) {
		return allPairs.length;
	}

	function feeTo() external pure override returns (address) {
		return address(0);
	}

	function feeToSetter() external pure override returns (address) {
		return address(0);
	}

	function setFeeTo(address) external override {}

	function setFeeToSetter(address) external override {}
}

contract MockUniswapV2Router is IUniswapV2Router {
	address public immutable override factory;
	address public immutable override WETH;

	constructor(address _factory, address _weth) {
		factory = _factory;
		WETH = _weth;
	}

	function addLiquidity(
		address tokenA,
		address tokenB,
		uint256 amountADesired,
		uint256 amountBDesired,
		uint256 amountAMin,
		uint256 amountBMin,
		address to,
		uint256 deadline
	) external returns (uint256 amountA, uint256 amountB, uint256 liquidity) {
		amountA = amountADesired >= amountAMin ? amountADesired : amountAMin;
		amountB = amountBDesired >= amountBMin ? amountBDesired : amountBMin;
		liquidity = 1000;
	}

	function addLiquidityEth(
		address token,
		uint256 amountTokenDesired,
		uint256 amountTokenMin,
		uint256 amountEthMin,
		address to,
		uint256 deadline
	) external payable returns (uint256 amountToken, uint256 amountEth, uint256 liquidity) {
		amountToken = amountTokenDesired >= amountTokenMin ? amountTokenDesired : amountTokenMin;
		amountEth = msg.value >= amountEthMin ? msg.value : amountEthMin;
		liquidity = 1000;
	}

	function removeLiquidity(address, address, uint256, uint256 amountAMin, uint256 amountBMin, address, uint256)
		external
		pure
		override
		returns (uint256, uint256)
	{
		return (amountAMin, amountBMin);
	}

	function removeLiquidityEth(address, uint256, uint256 amountTokenMin, uint256 amountEthMin, address, uint256)
		external
		pure
		override
		returns (uint256, uint256)
	{
		return (amountTokenMin, amountEthMin);
	}

	function removeLiquidityWithPermit(
		address,
		address,
		uint256,
		uint256 amountAMin,
		uint256 amountBMin,
		address,
		uint256,
		bool,
		uint8,
		bytes32,
		bytes32
	) external pure override returns (uint256, uint256) {
		return (amountAMin, amountBMin);
	}

	function removeLiquidityEthWithPermit(
		address,
		uint256,
		uint256 amountTokenMin,
		uint256 amountEthMin,
		address,
		uint256,
		bool,
		uint8,
		bytes32,
		bytes32
	) external pure override returns (uint256, uint256) {
		return (amountTokenMin, amountEthMin);
	}

	function swapExactTokensForTokens(
		uint256 amountIn,
		uint256 amountOutMin,
		address[] calldata path,
		address to,
		uint256 deadline
	) external returns (uint256[] memory amounts) {
		amounts = new uint256[](path.length);
		amounts[0] = amountIn;
		amounts[amounts.length - 1] = amountOutMin + 1;

		bool success = MockERC20(path[0]).transferFrom(msg.sender, address(this), amountIn);
		require(success, "Token transfer failed");

		MockERC20(path[path.length - 1]).mint(to, amounts[amounts.length - 1]);

		return amounts;
	}

	function swapTokensForExactTokens(
		uint256 amountOut,
		uint256 amountInMax,
		address[] calldata path,
		address to,
		uint256 deadline
	) external returns (uint256[] memory amounts) {
		amounts = new uint256[](path.length);
		amounts[0] = amountInMax / 2;
		amounts[amounts.length - 1] = amountOut;

		bool success = MockERC20(path[0]).transferFrom(msg.sender, address(this), amounts[0]);
		require(success, "Token transfer failed");

		MockERC20(path[path.length - 1]).mint(to, amountOut);

		return amounts;
	}

	function swapExactTokensForEth(uint256 amountOutMin, address[] calldata path, address to, uint256 deadline)
		external
		payable
		override
		returns (uint256[] memory amounts)
	{
		amounts = new uint256[](path.length);
		amounts[0] = msg.value;
		amounts[1] = msg.value * 900;

		MockERC20(path[1]).mint(to, amounts[1]);

		return amounts;
	}

	function swapTokensForExactEth(
		uint256 amountOut,
		uint256 amountInMax,
		address[] calldata path,
		address to,
		uint256 deadline
	) external override returns (uint256[] memory amounts) {
		amounts = new uint256[](path.length);
		amounts[0] = amountInMax / 2;
		amounts[1] = amountOut;

		bool success = MockERC20(path[0]).transferFrom(msg.sender, address(this), amounts[0]);
		require(success, "Token transfer failed");
		(bool ethSuccess,) = to.call{value: amountOut}("");
		require(ethSuccess, "ETH transfer failed");

		return amounts;
	}

	function swapEthForExactTokens(
		uint256 amountIn,
		uint256 amountOutMin,
		address[] calldata path,
		address to,
		uint256 deadline
	) external override returns (uint256[] memory amounts) {
		amounts = new uint256[](path.length);
		amounts[0] = amountIn;
		amounts[1] = amountOutMin;

		bool success = MockERC20(path[0]).transferFrom(msg.sender, address(this), amountIn);
		require(success, "Token transfer failed");
		(bool ethSuccess,) = to.call{value: amountOutMin}("");
		require(ethSuccess, "ETH transfer failed");

		return amounts;
	}

	function swapEthForExactTokens(uint256 amountOut, address[] calldata path, address to, uint256 deadline)
		external
		payable
		override
		returns (uint256[] memory amounts)
	{
		amounts = new uint256[](path.length);
		amounts[0] = msg.value;
		amounts[1] = amountOut;

		bool success = MockERC20(path[1]).transfer(to, amountOut);
		require(success, "Token transfer failed");

		return amounts;
	}

	function quote(uint256 amountA, uint256 reserveA, uint256 reserveB)
		external
		pure
		override
		returns (uint256 amountB)
	{
		require(amountA > 0 && reserveA > 0 && reserveB > 0, "Invalid input");
		amountB = (amountA * reserveB) / reserveA;
	}

	function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut)
		external
		pure
		override
		returns (uint256 amountOut)
	{
		require(amountIn > 0 && reserveIn > 0 && reserveOut > 0, "Invalid input");
		uint256 amountInWithFee = amountIn * 997;
		uint256 numerator = amountInWithFee * reserveOut;
		uint256 denominator = (reserveIn * 1000) + amountInWithFee;
		amountOut = numerator / denominator;
	}

	function getAmountIn(uint256 amountOut, uint256 reserveIn, uint256 reserveOut)
		external
		pure
		override
		returns (uint256 amountIn)
	{
		require(amountOut > 0 && reserveIn > 0 && reserveOut > 0, "Invalid input");
		uint256 numerator = reserveIn * amountOut * 1000;
		uint256 denominator = (reserveOut - amountOut) * 997;
		amountIn = (numerator / denominator) + 1;
	}

	function getAmountsOut(uint256 amountIn, address[] calldata path)
		external
		pure
		override
		returns (uint256[] memory amounts)
	{
		amounts = new uint256[](path.length);
		amounts[0] = amountIn;
		for (uint256 i = 0; i < path.length - 1; i++) {
			amounts[i + 1] = (amounts[i] * 997) / 1000;
		}
	}

	function getAmountsIn(uint256 amountOut, address[] calldata path)
		external
		pure
		override
		returns (uint256[] memory amounts)
	{
		amounts = new uint256[](path.length);
		amounts[amounts.length - 1] = amountOut;
		for (uint256 i = path.length - 1; i > 0; i--) {
			amounts[i - 1] = (amounts[i] * 1000) / 997;
		}
	}
}
