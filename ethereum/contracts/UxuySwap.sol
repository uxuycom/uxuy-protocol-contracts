//SPDX-License-Identifier: UXUY
pragma solidity ^0.8.11;

import "./interfaces/ISwapAdapter.sol";
import "./interfaces/ISwap.sol";
import "./libraries/BrokerBase.sol";
import "./libraries/SafeNativeAsset.sol";
import "./libraries/SafeERC20.sol";

contract UxuySwap is ISwap, BrokerBase {
    using SafeNativeAsset for address;
    using SafeERC20 for IERC20;

    function swap(
        SwapParams calldata params
    ) external whenNotPaused onlyAllowedCaller noDelegateCall returns (uint256 amountOut) {
        ISwapAdapter adapter = _getAdapter(params.provider);
        address tokenOut = params.path[params.path.length - 1];
        uint256 balanceBefore = 0;
        if (tokenOut.isNativeAsset()) {
            balanceBefore = params.recipient.balance;
        } else {
            balanceBefore = IERC20(tokenOut).balanceOf(params.recipient);
        }
        adapter.swap(
            ISwapAdapter.SwapParams({
                router: params.router,
                path: params.path,
                amountIn: params.amountIn,
                minAmountOut: params.minAmountOut,
                recipient: params.recipient,
                data: params.data
            })
        );
        if (tokenOut.isNativeAsset()) {
            amountOut = params.recipient.balance - balanceBefore;
        } else {
            amountOut = IERC20(tokenOut).balanceOf(params.recipient) - balanceBefore;
        }
        require(amountOut >= params.minAmountOut, "UxuySwap: swapped amount less than minAmountOut");
    }

    function _getAdapter(address provider) internal pure returns (ISwapAdapter) {
        require(provider != address(0), "UxuySwap: provider not found");
        return ISwapAdapter(provider);
    }
}
