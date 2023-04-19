//SPDX-License-Identifier: UXUY
pragma solidity ^0.8.11;

import "../interfaces/bridges/IConnext.sol";
import "../interfaces/tokens/IWrappedNativeAsset.sol";
import "../libraries/BridgeAdapterBase.sol";
import "../libraries/SafeNativeAsset.sol";
import "../libraries/SafeERC20.sol";

contract ConnexBridgeAdapter is BridgeAdapterBase {
    using SafeNativeAsset for address;
    using SafeERC20 for IERC20;

    IConnext private immutable _connext;
    address internal _wrapperAddress;
    mapping(uint32 => address) internal _unwrapperAddresses;
    address internal _delegate;

    constructor(
        address connext,
        address wrapperAddress,
        uint32[] memory unwrapperChains,
        address[] memory unwrapperAddresses,
        address delegate
    ) {
        _connext = IConnext(connext);
        _wrapperAddress = wrapperAddress;
        _setUnwrappers(unwrapperChains, unwrapperAddresses);
        _delegate = delegate;
    }

    function setUnwrappers(uint32[] calldata chains, address[] calldata addresses) external onlyOwner {
        _setUnwrappers(chains, addresses);
    }

    function _setUnwrappers(uint32[] memory chains, address[] memory addresses) internal {
        require(chains.length == addresses.length, "ConnexBridgeAdapter: chains and addresses length mismatch");
        for (uint256 i = 0; i < chains.length; i++) {
            _unwrapperAddresses[chains[i]] = addresses[i];
        }
    }

    function setDelegate(address delegate) external onlyOwner {
        _delegate = delegate;
    }

    function supportSwap() external pure returns (bool) {
        return false;
    }

    function bridge(
        BridgeParams calldata params
    ) external payable whenNotPaused onlyAllowedCaller noDelegateCall returns (uint256, uint256) {
        address tokenIn = params.tokenIn;
        uint256 amountIn = params.amountIn;
        uint256 relayerFee = abi.decode(params.data, (uint256));
        if (tokenIn.isNativeAsset()) {
            require(amountIn >= relayerFee, "ConnexBridgeAdapter: insufficient native asset for relayer fee");
            tokenIn = _wrapperAddress;
            amountIn = amountIn - relayerFee;
            IWrappedNativeAsset(tokenIn).deposit{value: amountIn}();
        } else {
            revert("ConnexBridgeAdapter: only support native asset as input");
        }
        IERC20(tokenIn).safeApproveToMax(address(_connext), amountIn);
        require(amountIn >= params.minAmountOut, "ConnexBridgeAdapter: insufficient amount in");
        uint256 slippage = ((amountIn - params.minAmountOut) * 10000) / amountIn;
        address toAddress;
        bytes memory data;
        if (params.tokenOut.isNativeAsset()) {
            toAddress = _unwrapperAddresses[uint32(params.chainIDOut)];
            require(toAddress != address(0), "ConnexBridgeAdapter: unwrapper not found");
            data = abi.encode(params.recipient);
        } else {
            toAddress = params.recipient;
        }
        bytes32 txnID = _connext.xcall{value: relayerFee}(
            uint32(params.chainIDOut),
            toAddress,
            tokenIn,
            _delegate,
            amountIn,
            slippage,
            data
        );
        return (0, uint256(txnID));
    }
}
