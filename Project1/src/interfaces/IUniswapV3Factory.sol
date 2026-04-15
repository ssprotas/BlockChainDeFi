// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IUniswapV3Factory {
	event PoolCreated(
		address indexed token0, address indexed token1, uint24 indexed fee, int24 tickSpacing, address pool
	);

	event FeeAmountEnabled(uint24 indexed fee, int24 indexed tickSpacing);

	event OwnerChanged(address indexed oldOwner, address indexed newOwner);

	function owner() external view returns (address);

	function feeAmountTickSpacing(uint24 fee) external view returns (int24);

	function enableFeeAmount(uint24 fee, int24 tickSpacing) external;

	function getPool(address tokenA, address tokenB, uint24 fee) external view returns (address pool);

	function createPool(address tokenA, address tokenB, uint24 fee) external returns (address pool);

	function setOwner(address _owner) external;
}
