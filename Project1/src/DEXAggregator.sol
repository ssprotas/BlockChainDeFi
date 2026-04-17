// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {IUniswapV2Router} from "./interfaces/IUniswapV2Router.sol";
import {ISwapRouter} from "./interfaces/ISwapRouter.sol";
import {PriceFetcher} from "./PriceFetcher.sol";
import {RouteFinder} from "./RouteFinder.sol";

contract DEXAggregator is Ownable, Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    uint24[] private constant V3_FEES = [500, 3000, 10000];

    constructor(
        address initialOwner,
        address _uniV2Factory,
        address _uniV2Router,
        address _uniV3Factory,
        address _uniV3Router
    ) Ownable(initialOwner) {
        if (
            _uniV2Factory == address(0) || _uniV2Router == address(0) || _uniV3Factory == address(0)
                || _uniV3Router == address(0)
        ) {
            revert InvalidAddress();
        }

        uniV2Factory = _uniV2Factory;
        uniV2Router = _uniV2Router;
        uniV3Factory = _uniV3Factory;
        uniV3Router = _uniV3Router;

        priceFetcher = new PriceFetcher();
        routeFinder = new RouteFinder();

        protocolFee = 25;
        feeRecipient = initialOwner;
    }

    uint256 private constant BASIS_POINTS = 10000;
    uint256 private constant MAX_SLIPPAGE = 500;
    uint256 private constant MAX_UINT256 = type(uint256).max;

    PriceFetcher public priceFetcher;
    RouteFinder public routeFinder;

    address public uniV2Factory;
    address public uniV2Router;
    address public uniV3Factory;
    address public uniV3Router;

    uint256 public protocolFee;
    address public feeRecipient;

    uint256 public totalSwapsExecuted;
    uint256 public totalVolumeProcessed;

    event SwapExecuted(
        address indexed tokenIn,
        address indexed tokenOut,
        uint256 amountIn,
        uint256 amountOut,
        uint8 dexType,
        uint256 priceImpact,
        uint256 feeTaken
    );

    event ProtocolFeeUpdated(uint256 newFee);
    event FeeRecipientUpdated(address newRecipient);
    event DEXConfigUpdated(address indexed dexAddress);

    error InvalidAmount();
    error InvalidSlippage();
    error InsufficientOutput();
    error SwapFailed();
    error Unauthorized();
    error InvalidAddress();

    function swapWithBestRoute(address tokenIn, address tokenOut, uint256 amountIn, uint256 minAmountOut)
        external
        nonReentrant
        whenNotPaused
        returns (uint256 amountOut)
    {
        if (amountIn == 0) revert InvalidAmount();
        if (tokenIn == tokenOut) revert InvalidAddress();

        SafeERC20.safeTransferFrom(IERC20(tokenIn), msg.sender, address(this), amountIn);

        (uint256 v2Output, uint256 v2Impact) =
            priceFetcher.getPriceFromUniswapV2(uniV2Factory, tokenIn, tokenOut, amountIn);

        uint256 bestV3Output = 0;
        uint24 bestV3Fee = 0;
        uint256 bestV3Impact = BASIS_POINTS;

        for (uint i = 0; i < V3_FEES.length; i++) {
            uint24 fee = V3_FEES[i];
            
            (uint256 v3Output, uint256 v3Impact) =
                priceFetcher.getPriceFromUniswapV3(uniV3Factory, tokenIn, tokenOut, fee, amountIn);
            
            if (v3Output > bestV3Output) {
                bestV3Output = v3Output;
                bestV3Fee = fee;
                bestV3Impact = v3Impact;
            }
        }

        RouteFinder.RouteInfo memory bestRoute = routeFinder.findBestDirectRoute(
            tokenIn, tokenOut, v2Output, v2Impact, bestV3Output, bestV3Impact, bestV3Fee
        );

        if (bestRoute.expectedOutput < minAmountOut) revert InsufficientOutput();

        if (bestRoute.dexType == 1) {
            amountOut = _executeUniswapV2Swap(tokenIn, tokenOut, amountIn, bestRoute.expectedOutput);
        } else {
            amountOut = _executeUniswapV3Swap(tokenIn, tokenOut, amountIn, bestRoute.expectedOutput, bestV3Fee);
        }

        uint256 feeTaken = (amountOut * protocolFee + BASIS_POINTS - 1) / BASIS_POINTS;
        uint256 amountToUser = amountOut - feeTaken;

        if (feeTaken > 0) {
            SafeERC20.safeTransfer(IERC20(tokenOut), feeRecipient, feeTaken);
        }

        SafeERC20.safeTransfer(IERC20(tokenOut), msg.sender, amountToUser);

        totalSwapsExecuted++;
        totalVolumeProcessed += amountIn;

        emit SwapExecuted(tokenIn, tokenOut, amountIn, amountOut, bestRoute.dexType, bestRoute.priceImpact, feeTaken);

        return amountToUser;
    }

    function _executeUniswapV2Swap(address tokenIn, address tokenOut, uint256 amountIn, uint256 expectedOut)
        internal
        returns (uint256 amountOut)
    {
        IERC20 token = IERC20(tokenIn);
        SafeERC20.forceApprove(token, uniV2Router, amountIn);

        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = tokenOut;

        uint256 minOut = (expectedOut * (BASIS_POINTS - MAX_SLIPPAGE)) / BASIS_POINTS;

        uint256[] memory amounts = IUniswapV2Router(uniV2Router)
            .swapExactTokensForTokens(amountIn, minOut, path, address(this), block.timestamp + 300);

        return amounts[amounts.length - 1];
    }

    function _executeUniswapV3Swap(address tokenIn, address tokenOut, uint256 amountIn, uint256 expectedOut, uint24 fee)
        internal
        returns (uint256 amountOut)
    {
        IERC20 token = IERC20(tokenIn);
        SafeERC20.forceApprove(token, uniV3Router, amountIn);

        uint256 minOut = (expectedOut * (BASIS_POINTS - MAX_SLIPPAGE)) / BASIS_POINTS;
        if (minOut == 0) minOut = 1;

        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
            tokenIn: tokenIn,
            tokenOut: tokenOut,
            fee: fee,
            recipient: address(this),
            deadline: block.timestamp + 300,
            amountIn: amountIn,
            amountOutMinimum: minOut,
            sqrtPriceLimitX96: 0
        });

        amountOut = ISwapRouter(uniV3Router).exactInputSingle(params);

        return amountOut;
    }

    function getQuote(address tokenIn, address tokenOut, uint256 amountIn)
        external
        view
        returns (uint256 outputAmount, uint256 priceImpact, uint8 dexRecommendation)
    {
        if (amountIn == 0) revert InvalidAmount();

        (uint256 v2Output, uint256 v2Impact) =
            priceFetcher.getPriceFromUniswapV2(uniV2Factory, tokenIn, tokenOut, amountIn);

        uint256 bestV3Output = 0;
        uint256 bestV3Impact = BASIS_POINTS;

        for (uint i = 0; i < V3_FEES.length; i++) {
            uint24 fee = V3_FEES[i];
            
            (uint256 v3Output, uint256 v3Impact) =
                priceFetcher.getPriceFromUniswapV3(uniV3Factory, tokenIn, tokenOut, fee, amountIn);
            
            if (v3Output > bestV3Output) {
                bestV3Output = v3Output;
                bestV3Impact = v3Impact;
            }
        }

        if (bestV3Output > v2Output) {
            return (bestV3Output, bestV3Impact, 2);
        } else {
            return (v2Output, v2Impact, 1);
        }
    }

    function setProtocolFee(uint256 newFee) external onlyOwner {
        require(newFee <= 1000, "Fee too high");
        protocolFee = newFee;
        emit ProtocolFeeUpdated(newFee);
    }

    function setFeeRecipient(address _feeRecipient) external onlyOwner {
        if (_feeRecipient == address(0)) revert InvalidAddress();
        feeRecipient = _feeRecipient;
        emit FeeRecipientUpdated(_feeRecipient);
    }

    function setUniV2Config(address _factory, address _router) external onlyOwner {
        if (_factory == address(0) || _router == address(0)) revert InvalidAddress();
        uniV2Factory = _factory;
        uniV2Router = _router;
        emit DEXConfigUpdated(_factory);
    }

    function setUniV3Config(address _factory, address _router) external onlyOwner {
        if (_factory == address(0) || _router == address(0)) revert InvalidAddress();
        uniV3Factory = _factory;
        uniV3Router = _router;
        emit DEXConfigUpdated(_factory);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function emergencyWithdraw(address token) external onlyOwner {
        uint256 balance = IERC20(token).balanceOf(address(this));
        if (balance > 0) {
            SafeERC20.safeTransfer(IERC20(token), msg.sender, balance);
        }
    }

    function getStats() external view returns (uint256 swaps, uint256 volume, uint256 fee, address feeRecip) {
        return (totalSwapsExecuted, totalVolumeProcessed, protocolFee, feeRecipient);
    }
}