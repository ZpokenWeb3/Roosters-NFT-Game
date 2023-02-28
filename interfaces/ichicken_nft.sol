// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

interface IChicken_NFT {
    function hatchRooster(address account, uint256 eggQuality) external returns (uint256);
    function hatchHen(address account, uint256 eggQuality) external returns (uint256);
    function setStaked(uint256 _id, bool _status) external;
    function plusOneWinsCounter(uint256 _id) external;
    function isStaked(uint256 _id) external view returns (bool);
    function getStats(uint256 _id) external view returns (uint256[7] memory chickenStats);
    function getType(uint256 _id) external view returns (uint);
    function ownerOf(uint256 _id) external view returns (address);
    function roosterToBones(uint256 _roosterId) external returns (uint256);
    function getMaxBaseStats() external view returns (uint256 max_speed, uint256 max_luck);
    function mintMirror(uint256[5] memory _roosterStats) external returns (uint256);
    function craftSacrifice(uint256 _chickenId) external;
}