// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

interface IBattle {

    struct FightData {
            uint256 stakeId1;
            uint256 stakeId2; 
            uint256 timestamp;
            uint256 winnerStakeId; // 0 - fight was not initiated
            uint256 loserBonesId; // new minted bones NFT id
        }

    function getFightData(uint256 _fightId) external view returns (FightData memory);

}