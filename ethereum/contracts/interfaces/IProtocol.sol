//SPDX-License-Identifier: UXUY
pragma solidity ^0.8.11;

interface IProtocol {
    struct SwapParams {
        address provider;
        address router;
        address[] path;
        uint256 minAmountOut;
        bytes data;
    }

    struct BridgeParams {
        address provider;
        address router;
        address tokenIn;
        uint256 chainIDOut;
        address tokenOut;
        uint256 minAmountOut;
        bytes data;
    }

    struct TradeParams {
        uint256 amountIn;
        SwapParams[] swaps;
        BridgeParams bridge;
        address recipient;
        address feeShareRecipient;
        uint256 extraFeeAmountIn; // Extra fee deducted to pay the gas fee
        SwapParams[] extraFeeSwaps;
        uint256 deadline;
        uint256 orderId;
    }

    // @dev Emitted when fee rate is updated
    event FeeRateChanged(uint256 feeRate, uint256 feeShareRate);

    // @dev Emitted when trade is executed
    event Traded(
        address indexed sender,
        uint256 orderId,
        address indexed recipient,
        address indexed feeShareRecipient,
        address tokenIn,
        uint256 amountIn,
        uint256 chainIDOut,
        address tokenOut,
        uint256 amountOut,
        uint256 bridgeTxnID,
        address feeToken,
        uint256 amountFee,
        uint256 amountFeeShare,
        uint256 amountExtraFee
    );

    // @dev gets the swap contract
    function swapContract() external view returns (address);

    // @dev gets the bridge contract
    function bridgeContract() external view returns (address);

    // @dev gets the fee denominator
    function feeDenominator() external pure returns (uint256);

    // @dev gets the total fee rate
    function feeRate() external view returns (uint256);

    // @dev gets the fee share rate
    function feeShareRate() external view returns (uint256);

    // @dev trade between tokens
    function trade(TradeParams calldata params) external payable returns (uint256 amountOut, uint256 bridgeTxnID);
}
