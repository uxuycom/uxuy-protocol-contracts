//SPDX-License-Identifier: UXUY
pragma solidity ^0.8.11;

interface ISwap {
    struct SwapParams {
        address provider;
        address router;
        address[] path;
        uint256 amountIn;
        uint256 minAmountOut;
        address recipient;
        bytes data;
    }

    // @dev calls swap adapter to fulfill the exchange
    // @return amountOut the amount of tokens transferred out, guarantee amountOut >= params.minAmountOut
    function swap(SwapParams calldata params) external returns (uint256 amountOut);
}
