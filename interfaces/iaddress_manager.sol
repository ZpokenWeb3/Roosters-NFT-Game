// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

interface IAddressManager {
    function getAddress(string memory _name) external view returns (address);
}