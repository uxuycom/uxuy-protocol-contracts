//SPDX-License-Identifier: UXUY
pragma solidity ^0.8.11;

interface ISwapAdapter {
    struct SwapParams {
        address[] path;
        uint amountIn;
        uint minAmountOut;
        address recipient;
        bytes data;
    }

    function getAmountIn(address[] memory path, uint amountOut) external returns (uint amountIn, bytes memory swapData);

    function getAmountOut(
        address[] memory path,
        uint amountIn
    ) external returns (uint amountOut, bytes memory swapData);

    // @dev view only version of getAmountIn
    function getAmountInView(
        address[] memory path,
        uint amountOut
    ) external view returns (uint amountIn, bytes memory swapData);

    // @dev view only version of getAmountOut
    function getAmountOutView(
        address[] memory path,
        uint amountIn
    ) external view returns (uint amountOut, bytes memory swapData);

    // @dev calls swap router to fulfill the exchange
    // @return amountOut the amount of tokens transferred out, may be 0 if this can not be fetched
    function swap(SwapParams calldata params) external payable returns (uint amountOut);
}
