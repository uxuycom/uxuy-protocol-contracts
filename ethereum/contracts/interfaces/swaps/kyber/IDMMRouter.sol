// SPDX-License-Identifier: UXUY
pragma solidity ^0.8.11;

import "./IDMMExchangeRouter.sol";

interface IDMMRouter is IDMMExchangeRouter {
    function factory() external pure returns (address);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata poolsPath,
        IERC20[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata poolsPath,
        IERC20[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata poolsPath,
        IERC20[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function weth() external pure returns (address);
}
