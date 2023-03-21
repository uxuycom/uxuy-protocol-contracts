//SPDX-License-Identifier: UXUY
pragma solidity ^0.8.11;

interface IAggregationExecutor {
    function execute(address msgSender) external payable;
}
