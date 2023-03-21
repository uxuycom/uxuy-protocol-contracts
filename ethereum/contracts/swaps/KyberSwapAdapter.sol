//SPDX-License-Identifier: UXUY
pragma solidity ^0.8.11;

import "../interfaces/swaps/kyber/IKyberNetworkProxy.sol";
import "../interfaces/swaps/kyber/IDMMPool.sol";
import "../interfaces/swaps/kyber/IDMMRouter.sol";
import "../libraries/SwapAdapterBase.sol";
import "../libraries/SafeNativeAsset.sol";

contract KyberSwapAdapter is SwapAdapterBase {
    using SafeNativeAsset for address;
    using SafeERC20 for IERC20;

    IDMMRouter private immutable _router;

    constructor(address router) {
        _router = IDMMRouter(router);
        _setWrappedNativeAsset(_router.weth());
    }

    function getAmountInView(
        address[] memory path,
        uint amountOut
    ) public view override returns (uint amountIn, bytes memory swapData) {
        swapData = "";
        _convertPath(path);
        try _router.getAmountsIn(amountOut, _getPoolPath(path), _getERC20Path(path)) returns (uint256[] memory v) {
            require(v.length >= 2);
            amountIn = v[0];
        } catch {
            amountIn = 0;
        }
    }

    function getAmountOutView(
        address[] memory path,
        uint amountIn
    ) public view override returns (uint amountOut, bytes memory swapData) {
        swapData = "";
        _convertPath(path);
        try _router.getAmountsOut(amountIn, _getPoolPath(path), _getERC20Path(path)) returns (uint256[] memory v) {
            require(v.length >= 2);
            amountOut = v[v.length - 1];
        } catch {
            amountOut = 0;
        }
    }

    function _getERC20Path(address[] memory path) internal pure returns (IERC20[] memory erc20Path) {
        erc20Path = new IERC20[](path.length);
        for (uint i = 0; i < path.length; i++) {
            erc20Path[i] = IERC20(path[i]);
        }
    }

    function _getPoolPath(address[] memory path) internal view returns (address[] memory poolPath) {
        poolPath = new address[](path.length - 1);
        for (uint i = 0; i < path.length - 1; i++) {
            poolPath[i] = _getPool(path[i], path[i + 1]);
        }
    }

    function _getPool(address tokenIn, address tokenOut) internal view returns (address pool) {
        IDMMFactory factory = IDMMFactory(_router.factory());
        address[] memory pools = factory.getPools(IERC20(tokenIn), IERC20(tokenOut));

        uint highestKLast = 0;
        pool = address(0);
        for (uint i = 0; i < pools.length; i++) {
            uint currKLast = IDMMPool(pools[i]).kLast();
            if (currKLast > highestKLast) {
                highestKLast = currKLast;
                pool = pools[i];
            }
        }
    }

    function swap(
        SwapParams calldata params
    ) external payable whenNotPaused onlyAllowedCaller noDelegateCall handleWrap(params) returns (uint amountOut) {
        address[] memory path = _convertPath(params.path);
        address[] memory poolPath = _getPoolPath(path);
        IERC20[] memory erc20Path = _getERC20Path(path);
        address tokenIn = params.path[0];
        if (tokenIn.isNativeAsset()) {
            uint[] memory amounts = _router.swapExactETHForTokens{value: params.amountIn}(
                params.minAmountOut,
                poolPath,
                erc20Path,
                params.recipient,
                type(uint).max
            );
            require(amounts.length >= 2);
            amountOut = amounts[amounts.length - 1];
        } else {
            IERC20(tokenIn).safeApproveToMax(address(_router), params.amountIn);
            if (params.path[params.path.length - 1].isNativeAsset()) {
                uint[] memory amounts = _router.swapExactTokensForETH(
                    params.amountIn,
                    params.minAmountOut,
                    poolPath,
                    erc20Path,
                    params.recipient,
                    type(uint).max
                );
                amountOut = amounts[amounts.length - 1];
            } else {
                uint[] memory amounts = _router.swapExactTokensForTokens(
                    params.amountIn,
                    params.minAmountOut,
                    poolPath,
                    erc20Path,
                    params.recipient,
                    type(uint).max
                );
                amountOut = amounts[amounts.length - 1];
            }
        }
    }
}
