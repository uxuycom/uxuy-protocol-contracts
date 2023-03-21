//SPDX-License-Identifier: UXUY
pragma solidity ^0.8.11;

import "../libraries/SwapAdapterBase.sol";
import "../interfaces/swaps/oneinch/IAggregatorExecutor.sol";
import "../interfaces/swaps/oneinch/IAggregator.sol";
import "../libraries/SafeNativeAsset.sol";
import "../libraries/SafeERC20.sol";

contract OneInchSwapAdapter is SwapAdapterBase {
    using SafeNativeAsset for address;
    using SafeERC20 for IERC20;

    address private immutable _aggregator;

    constructor(address aggregator) {
        _aggregator = aggregator;
    }

    function swap(
        SwapParams calldata params
    )
        external
        payable
        whenNotPaused
        onlyAllowedCaller
        noDelegateCall
        refundUnused(params.path[0])
        returns (uint amountOut)
    {
        if (!params.path[0].isNativeAsset()) {
            IERC20(params.path[0]).safeApproveToMax(address(_aggregator), params.amountIn);
        }
        bool success;
        bytes memory result;
        (success, result) = _aggregator.call{value: params.path[0].isNativeAsset() ? params.amountIn : 0}(params.data);
        if (!success) {
            revert("OneInchSwapAdapter: call 1inch failed");
        }
        (amountOut, ) = abi.decode(result, (uint, uint));
    }
}
