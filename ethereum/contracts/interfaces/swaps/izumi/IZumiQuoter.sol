//SPDX-License-Identifier: UXUY
pragma solidity ^0.8.11;

interface IZumiQuoter {
    function swapAmount(
        uint amountIn,
        bytes memory path
    ) external payable returns (uint256 acquire, int24[] memory pointAfterList);
}
