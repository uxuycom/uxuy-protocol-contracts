//SPDX-License-Identifier: UXUY
pragma solidity ^0.8.11;

interface ISwapAdapter {
    struct SwapParams {
        address router;
        address[] path;
        uint256 amountIn;
        uint256 minAmountOut;
        address recipient;
        bytes data;
    }

    // @dev calls swap router to fulfill the exchange
    // @return amountOut the amount of tokens transferred out, may be 0 if this can not be fetched
    function swap(SwapParams calldata params) external payable returns (uint256 amountOut);
}
