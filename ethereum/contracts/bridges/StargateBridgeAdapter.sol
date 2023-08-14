//SPDX-License-Identifier: UXUY
pragma solidity ^0.8.11;

import "../interfaces/bridges/IStargateRouter.sol";
import "../libraries/BridgeAdapterBase.sol";
import "../libraries/SafeNativeAsset.sol";
import "../libraries/SafeERC20.sol";

contract StargateBridgeAdapter is BridgeAdapterBase {
    using SafeNativeAsset for address;
    using SafeERC20 for IERC20;

    struct BridgeState {
        uint256 amountIn;
        uint8 tokenInDecimals;
        uint16 destChainId;
        uint256 srcPoolId;
        uint256 dstPoolId;
        address refundAddress;
        uint256 fee;
    }

    uint8 private constant FUNCTION_TYPE_SWAP_REMOTE = 1;

    IStargateRouter private immutable _stargateRouter;

    uint8 private _nativeAssetDecimals;

    mapping(address => bool) private _acceptedTokens;

    event AcceptedTokenChanged(address token, bool accepted);

    constructor(
        address router,
        uint8 nativeAssetDecimals,
        address[] memory acceptedTokens
    ) {
        _stargateRouter = IStargateRouter(router);
        _nativeAssetDecimals = nativeAssetDecimals;
        for (uint256 i = 0; i < acceptedTokens.length; i++) {
            _acceptedTokens[acceptedTokens[i]] = true;
            emit AcceptedTokenChanged(acceptedTokens[i], true);
        }
    }

    // @dev updates accepted tokens
    function updateAcceptedTokens(address[] calldata tokens, bool accepted) external onlyOwner {
        for (uint256 i = 0; i < tokens.length; i++) {
            if (accepted) {
                _acceptedTokens[tokens[i]] = true;
            } else {
                delete _acceptedTokens[tokens[i]];
            }
            emit AcceptedTokenChanged(tokens[i], accepted);
        }
    }

    function supportSwap() external pure returns (bool) {
        return false;
    }

    function bridge(
        BridgeParams calldata params
    ) external payable whenNotPaused onlyAllowedCaller noDelegateCall returns (uint256, uint256) {
        BridgeState memory state;
        require(_acceptedTokens[params.tokenIn], "StargateBridgeAdapter: token not accepted");
        (state.destChainId, state.srcPoolId, state.dstPoolId, state.refundAddress) = abi.decode(
            params.data,
            (uint16, uint256, uint256, address)
        );
        IStargateRouter.lzTxObj memory lzTxParams = IStargateRouter.lzTxObj({
            dstGasForCall: 0,
            dstNativeAmount: 0,
            dstNativeAddr: ""
        });
        (state.fee, ) = _stargateRouter.quoteLayerZeroFee(
            state.destChainId,
            FUNCTION_TYPE_SWAP_REMOTE,
            abi.encode(params.tokenOut),
            "",
            lzTxParams
        );
        state.amountIn = params.amountIn;
        state.tokenInDecimals = IERC20(params.tokenIn).decimals();
        IERC20(params.tokenIn).safeApproveToMax(address(_stargateRouter), state.amountIn);
        _stargateRouter.swap{value: state.fee}(
            state.destChainId,
            state.srcPoolId,
            state.dstPoolId,
            payable(state.refundAddress),
            state.amountIn,
            params.minAmountOut,
            lzTxParams,
            abi.encodePacked(params.recipient),
            ""
        );
        return (0, 0);
    }
}
