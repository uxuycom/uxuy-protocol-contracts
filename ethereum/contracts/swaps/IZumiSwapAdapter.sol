//SPDX-License-Identifier: UXUY
pragma solidity ^0.8.11;

import "../libraries/SwapAdapterBase.sol";
import "../libraries/SwapAdapterBase.sol";
import "../libraries/SafeNativeAsset.sol";
import "../libraries/SafeERC20.sol";
import "../libraries/Path.sol";
import "../interfaces/swaps/izumi/IZumiQuoter.sol";
import "../interfaces/swaps/izumi/IZumiRouter.sol";

contract IZumiSwapAdapter is SwapAdapterBase {
    using SafeNativeAsset for address;
    using SafeERC20 for IERC20;
    using Path for address[];

    IZumiQuoter private immutable _quoter;
    IZumiRouter private immutable _router;
    uint24[] private _feeRates;

    constructor(address quoter, address router, uint24[] memory feeRates) {
        _quoter = IZumiQuoter(quoter);
        _router = IZumiRouter(router);
        _setWrappedNativeAsset(_router.WETH9());
        _feeRates = feeRates;
    }

    function getAmountOut(
        address[] memory path,
        uint256 amountIn
    ) external override returns (uint256 amountOut, bytes memory swapData) {
        _convertPath(path);
        uint24[] memory bestFees = new uint24[](path.length - 1);
        address tokenIn = path[0];
        for (uint256 i = 1; i < path.length; i++) {
            uint24 bestFee = 0;
            address tokenOut = path[i];
            amountOut = 0;
            for (uint256 j = 0; j < _feeRates.length; j++) {
                try _quoter.swapAmount(uint128(amountIn), abi.encodePacked(tokenIn, _feeRates[j], tokenOut)) returns (
                    uint256 amount,
                    int24[] memory
                ) {
                    if (amount > amountOut) {
                        amountOut = amount;
                        bestFee = _feeRates[j];
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
        require(params.path.length >= 2 && params.path.length == poolFee.length + 1);
        address tokenIn = params.path[0];
        if (!tokenIn.isNativeAsset()) {
            IERC20(tokenIn).safeApproveToMax(address(_router), params.amountIn);
        }
        address[] memory swapPath = _convertPath(params.path);
        (, amountOut) = _router.swapAmount{value: tokenIn.isNativeAsset() ? params.amountIn : 0}(
            IZumiRouter.SwapAmountParams({
                path: swapPath.buildPath(poolFee),
                recipient: params.recipient,
                amount: uint128(params.amountIn),
                minAcquired: params.minAmountOut,
                deadline: type(uint256).max
            })
        );
    }
}
