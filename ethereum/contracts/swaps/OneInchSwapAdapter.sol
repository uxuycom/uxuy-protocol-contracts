//SPDX-License-Identifier: UXUY
pragma solidity ^0.8.11;

import "../libraries/SwapAdapterBase.sol";
import "../libraries/SafeNativeAsset.sol";
import "../libraries/SafeERC20.sol";

contract OneInchSwapAdapter is SwapAdapterBase {
    using SafeNativeAsset for address;
    using SafeERC20 for IERC20;

    constructor() {}

    function swap(
        SwapParams calldata params
    ) external payable whenNotPaused onlyAllowedCaller noDelegateCall returns (uint256 amountOut) {
        if (!params.path[0].isNativeAsset()) {
            IERC20(params.path[0]).safeApproveToMax(address(params.router), params.amountIn);
        }
        bool success;
        bytes memory result;
        (success, result) = params.router.call{value: params.path[0].isNativeAsset() ? params.amountIn : 0}(params.data);
        if (!success) {
            revert("OneInchSwapAdapter: call 1inch failed");
        }
        (amountOut, ) = abi.decode(result, (uint256, uint256));
    }
}

