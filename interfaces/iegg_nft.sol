// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

interface IEgg_NFT {
    function layEgg(address account, uint256 _breedCeiling, uint256 _bonusQuality) external returns (uint256);
}