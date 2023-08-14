//SPDX-License-Identifier: UXUY
pragma solidity ^0.8.11;

import "../interfaces/swaps/uniswap/v2/IUniswapV2Router.sol";
import "../libraries/SwapAdapterBase.sol";
import "../libraries/SafeNativeAsset.sol";
import "../libraries/SafeERC20.sol";

contract UniswapV2SwapAdapter is SwapAdapterBase {
    using SafeNativeAsset for address;
    using SafeERC20 for IERC20;

    uint256 internal constant UNEXPIRED = type(uint256).max;

    constructor(address wrappedAsset) {
        _setWrappedNativeAsset(wrappedAsset);
    }

    function getAmountIn(
        address router,
        address[] memory path,
        uint256 amountOut
    ) external virtual returns (uint256 amountIn, bytes memory swapData) {
        require(path.length >= 2, "UniswapV2SwapAdapter: invalid path");
        require(amountOut > 0, "UniswapV2SwapAdapter: request amount must be greater than 0");
        swapData = "";
        _convertPath(path);
        IUniswapV2Router _router = IUniswapV2Router(router);
        try _router.getAmountsIn(amountOut, path) returns (uint256[] memory v) {
            require(v.length >= 2, "UniswapV2SwapAdapter: invalid amounts");
            amountIn = v[0];
        } catch {
            amountIn = 0;
        }
    }

    function getAmountOut(
        address router,
        address[] memory path,
        uint256 amountIn
    ) external virtual returns (uint256 amountOut, bytes memory swapData) {
        require(path.length >= 2, "UniswapV2SwapAdapter: invalid path");
        require(amountIn > 0, "UniswapV2SwapAdapter: request amount must be greater than 0");
        swapData = "";
        _convertPath(path);
        IUniswapV2Router _router = IUniswapV2Router(router);
        try _router.getAmountsOut(amountIn, path) returns (uint256[] memory v) {
            require(v.length >= 2, "UniswapV2SwapAdapter: invalid amounts");
            amountOut = v[v.length - 1];
        } catch {
            amountOut = 0;
        }
    }

    function swap(
        SwapParams calldata params
    ) external payable whenNotPaused onlyAllowedCaller noDelegateCall handleWrap(params) returns (uint256 amountOut) {
        address tokenIn = params.path[0];
        if (tokenIn.isNativeAsset()) {
            amountOut = _swapExactETHForTokens(params.router, params.path, params.recipient, params.amountIn, params.minAmountOut);
        } else {
            IERC20(tokenIn).safeApproveToMax(params.router, params.amountIn);
            amountOut = _swapExactTokensForOthers(params.router, params.path, params.recipient, params.amountIn, params.minAmountOut);
        }
    }

    function _swapExactETHForTokens(
        address router,
        address[] memory path,
        address recipient,
        uint256 amountIn,
        uint256 minAmountOut
    ) internal returns (uint256 amountOut) {
        require(address(this).balance >= amountIn, "UniswapV2SwapAdapter: not enough native assets in transaction");
        path[0] = WrappedNativeAsset();
        IUniswapV2Router _router = IUniswapV2Router(router);
        try _router.swapExactETHForTokens{value: amountIn}(minAmountOut, path, recipient, UNEXPIRED) returns (
            uint256[] memory amounts
        ) {
            require(amounts.length >= 2, "UniswapV2SwapAdapter: invalid amounts");
            amountOut = amounts[amounts.length - 1];
        } catch {
            _router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amountIn}(
                minAmountOut,
                path,
                recipient,
                UNEXPIRED
            );
            amountOut = 0;
        }
    }

    function _swapExactTokensForOthers(
        address router,
        address[] memory path,
        address recipient,
        uint256 amountIn,
        uint256 minAmountOut
    ) internal returns (uint256 amountOut) {
        address tokenOut = path[path.length - 1];
        IUniswapV2Router _router = IUniswapV2Router(router);
        if (tokenOut.isNativeAsset()) {
            path[path.length - 1] = WrappedNativeAsset();
            try _router.swapExactTokensForETH(amountIn, minAmountOut, path, recipient, UNEXPIRED) returns (
                uint256[] memory amounts
            ) {
                require(amounts.length >= 2, "UniswapV2SwapAdapter: invalid amounts");
                amountOut = amounts[amounts.length - 1];
            } catch {
                _router.swapExactTokensForETHSupportingFeeOnTransferTokens(
                    amountIn,
                    minAmountOut,
                    path,
                    recipient,
                    UNEXPIRED
                );
                amountOut = 0;
            }
        } else {
            _convertPath(path);
            try _router.swapExactTokensForTokens(amountIn, minAmountOut, path, recipient, UNEXPIRED) returns (
                uint256[] memory amounts
            ) {
                require(amounts.length >= 2, "UniswapV2SwapAdapter: invalid amounts");
                amountOut = amounts[amounts.length - 1];
            } catch {
                _router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                    amountIn,
                    minAmountOut,
                    path,
                    recipient,
                    UNEXPIRED
                );
                amountOut = 0;
            }
        }
    }
}
