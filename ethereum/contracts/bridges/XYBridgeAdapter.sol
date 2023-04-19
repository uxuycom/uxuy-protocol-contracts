//SPDX-License-Identifier: UXUY
pragma solidity ^0.8.11;

import "../interfaces/bridges/IXYBridge.sol";
import "../libraries/BridgeAdapterBase.sol";
import "../libraries/SafeNativeAsset.sol";
import "../libraries/SafeERC20.sol";

contract XYBridgeAdapter is BridgeAdapterBase {
    using SafeNativeAsset for address;
    using SafeERC20 for IERC20;

    address private immutable _xyBridge;

    constructor(address xyBridge) {
        _xyBridge = xyBridge;
    }

    function supportSwap() external pure returns (bool) {
        return true;
    }

    function bridge(
        BridgeParams calldata params
    ) external payable whenNotPaused onlyAllowedCaller noDelegateCall returns (uint256, uint256) {
        bool success;
        bytes memory data;
        if (!params.tokenIn.isNativeAsset()) {
            IERC20(params.tokenIn).safeApproveToMax(_xyBridge, params.amountIn);
        }
        (success, data) = _xyBridge.call{value: params.tokenIn.isNativeAsset() ? params.amountIn : 0}(params.data);
        require(success, string(abi.encodePacked("XYBridgeAdapter: call xybridge failed: ", data)));

        return (0, 0);
    }
}
