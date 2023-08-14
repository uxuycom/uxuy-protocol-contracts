//SPDX-License-Identifier: UXUY
pragma solidity ^0.8.11;

import "../libraries/BridgeAdapterBase.sol";
import "../libraries/SafeERC20.sol";

contract UPoolBridgeAdapter is BridgeAdapterBase {
    using SafeERC20 for IERC20;

    mapping(address => bool) private _acceptedTokens;
    mapping(address => bool) private _uagents;

    event AcceptedTokenChanged(address token, bool accepted);
    event UAgentChanged(address account, bool uagent);

    event Transferred(
        address uagent,
        address outAddress,
        address outToken,
        uint256 outChainId,
        uint256 outMinAmount,
        address inToken,
        uint256 inAmount,
        uint256 orderId
    );

    struct BridgeState {
        address uagent;
        address recipient;
        uint256 orderId;
    }

    constructor(address[] memory acceptedTokens, address[] memory uagents) {
        for (uint256 i = 0; i < acceptedTokens.length; i++) {
            _acceptedTokens[acceptedTokens[i]] = true;
        }
        for (uint256 i = 0; i < uagents.length; i++) {
            _uagents[uagents[i]] = true;
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

    // @dev updates uagent accounts
    function updateUAgents(address[] calldata accounts, bool uagent) external onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            if (uagent) {
                _uagents[accounts[i]] = true;
            } else {
                delete _uagents[accounts[i]];
            }
            emit UAgentChanged(accounts[i], uagent);
        }
    }

    function supportSwap() external pure returns (bool) {
        return false;
    }

    function bridge(
        BridgeParams calldata params
    ) external payable whenNotPaused onlyAllowedCaller noDelegateCall returns (uint256, uint256) {
        BridgeState memory state;
        state.uagent = params.recipient;
        (state.orderId, state.recipient) = abi.decode(params.data, (uint256, address));

        require(_acceptedTokens[params.tokenIn], "UPoolBridgeAdapter: token not accepted");
        require(_uagents[params.recipient], "UPoolBridgeAdapter: illegal uagent");
        require(params.chainIDOut > 0, "UPoolBridgeAdapter: invalid chainIDOut");
        _safeTransferERC20(IERC20(params.tokenIn), state.uagent, params.amountIn);

        emit Transferred(
            state.uagent,
            state.recipient,
            params.tokenOut,
            params.chainIDOut,
            params.minAmountOut,
            params.tokenIn,
            params.amountIn,
            state.orderId
        );
        return (params.amountIn, 0);
    }
}
