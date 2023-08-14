//SPDX-License-Identifier: UXUY
pragma solidity ^0.8.11;

import "../interfaces/swaps/uniswap/v3/IQuoter.sol";
import "../interfaces/swaps/uniswap/v3/ISwapRouter.sol";
import "../libraries/SwapAdapterBase.sol";
import "../libraries/SafeNativeAsset.sol";
import "../libraries/SafeERC20.sol";
import "../libraries/Path.sol";

contract UniswapV3SwapAdapter is SwapAdapterBase {
    using SafeNativeAsset for address;
    using SafeERC20 for IERC20;
    using Path for address[];

    constructor(address wrappedAsset) {
        _setWrappedNativeAsset(wrappedAsset);
    }

    function getAmountIn(
        address router,
        address[] memory path,
        uint256 amountOut,
        uint24[] memory feeRates
    ) external virtual returns (uint256 amountIn, bytes memory swapData) {
        IQuoter _quoter = IQuoter(router);
        _convertPath(path);
        uint24[] memory bestFees = new uint24[](path.length - 1);
        address tokenOut = path[path.length - 1];
        for (uint256 i = path.length - 2; i >= 0; i--) {
            uint24 bestFee = 0;
            address tokenIn = path[i];
            amountIn = 0;
            for (uint256 j = 0; j < feeRates.length; j++) {
                try _quoter.quoteExactOutputSingle(tokenIn, tokenOut, feeRates[j], amountOut, 0) returns (
                    uint256 amount
                ) {
                    if (amount > 0 && (amountIn == 0 || amount < amountIn)) {
                        amountIn = amount;
                        bestFee = feeRates[j];
                    }
                } catch {}
            }
            if (amountIn == 0) {
                return (amountIn, swapData);
            }
            bestFees[i] = bestFee;
            tokenOut = tokenIn;
            amountOut = amountIn;
        }
        swapData = abi.encode(bestFees);
    }

    function getAmountOut(
        address router,
        address[] memory path,
        uint256 amountIn,
        uint24[] memory feeRates
    ) external virtual returns (uint256 amountOut, bytes memory swapData) {
        IQuoter _quoter = IQuoter(router);
        _convertPath(path);
        uint24[] memory bestFees = new uint24[](path.length - 1);
        address tokenIn = path[0];
        for (uint256 i = 1; i < path.length; i++) {
            uint24 bestFee = 0;
            address tokenOut = path[i];
            amountOut = 0;
            for (uint256 j = 0; j < feeRates.length; j++) {
                try _quoter.quoteExactInputSingle(tokenIn, tokenOut, feeRates[j], amountIn, 0) returns (
                    uint256 amount
                ) {
                    if (amount > amountOut) {
                        amountOut = amount;
                        bestFee = feeRates[j];
                    }
                } catch {}
            }
            if (amountOut == 0) {
                return (amountOut, swapData);
            }
            bestFees[i - 1] = bestFee;
            tokenIn = tokenOut;
            amountIn = amountOut;
        }
        swapData = abi.encode(bestFees);
    }

    function swap(
        SwapParams calldata params
    ) external payable whenNotPaused onlyAllowedCaller noDelegateCall handleWrap(params) returns (uint256 amountOut) {
        uint24[] memory poolFee = abi.decode(params.data, (uint24[]));
        require(params.path.length == poolFee.length + 1, "UniswapV3SwapAdapter: fee does not match path");
        address tokenIn = params.path[0];
        address tokenOut = params.path[params.path.length - 1];

        uint256 value = 0;
        if (tokenIn.isNativeAsset()) {
            value = params.amountIn;
        } else {
            IERC20(tokenIn).safeApproveToMax(params.router, params.amountIn);
        }
        address[] memory swapPath = _convertPath(params.path);
        address recipient = params.recipient;
        if (tokenOut.isNativeAsset()) {
            recipient = address(this);
        }

        if (swapPath.length == 2) {
            amountOut = ISwapRouter(params.router).exactInputSingle{value: value}(
                ISwapRouter.ExactInputSingleParams({
                    tokenIn: swapPath[0],
                    tokenOut: swapPath[1],
                    fee: poolFee[0],
                    recipient: recipient,
                    deadline: type(uint256).max,
                    amountIn: params.amountIn,
                    amountOutMinimum: params.minAmountOut,
                    sqrtPriceLimitX96: 0
                })
            );
        } else {
            amountOut = ISwapRouter(params.router).exactInput{value: value}(
                ISwapRouter.ExactInputParams({
                    path: swapPath.buildPath(poolFee),
                    recipient: recipient,
                    deadline: type(uint256).max,
                    amountIn: params.amountIn,
                    amountOutMinimum: params.minAmountOut
                })
            );
        }

        if (tokenOut.isNativeAsset()) {
            _unwrapNativeAsset(amountOut, params.recipient);
        }
    }
}
