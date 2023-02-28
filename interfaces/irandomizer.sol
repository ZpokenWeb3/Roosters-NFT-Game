// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

interface IRandomizer {
    function getRandomInRange(uint256 min, uint256 max, uint256 salt) external returns (uint);
}