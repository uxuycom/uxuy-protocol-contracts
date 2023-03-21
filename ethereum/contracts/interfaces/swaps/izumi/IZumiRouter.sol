//SPDX-License-Identifier: UXUY
pragma solidity ^0.8.11;

interface IZumiRouter {
    function WETH9() external view returns (address);

    struct SwapAmountParams {
        bytes path;
        address recipient;
        uint128 amount;
        uint256 minAcquired;
        uint256 deadline;
    }

    function swapAmount(SwapAmountParams calldata params) external payable returns (uint256 cost, uint256 acquire);

    struct SwapParams {
        address tokenX;
        address tokenY;
        uint24 fee;
        int24 boundaryPt;
        address recipient;
        uint128 amount;
        uint256 maxPayed;
        uint256 minAcquired;
        uint256 deadline;
    }

    function swapX2Y(SwapParams calldata swapParams) external payable;

    function swapY2X(SwapParams calldata swapParams) external payable;
}
