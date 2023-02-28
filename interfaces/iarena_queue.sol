// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

interface IArena_Queue {
    function insertItem(uint id, uint value) external returns (uint removedId);
    function getNearestNeighbor(uint id) external view returns (uint neighborId);
    function removeItem(uint id) external;
}