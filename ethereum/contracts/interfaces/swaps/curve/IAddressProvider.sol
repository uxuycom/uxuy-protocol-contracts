// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.11;

interface IAddressProvider {
    function get_address(uint id) external view returns (address addr);

    function max_id() external view returns (uint id);
}
