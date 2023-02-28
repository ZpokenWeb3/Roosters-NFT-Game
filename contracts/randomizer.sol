// SPDX-License-Identifier: None
pragma solidity ^0.8.0;


contract Randomizer {

    uint256 private requestId;

    function getRandomInRange(uint256 min, uint256 max, uint256 salt) external returns (uint) {
        uint randomnumber;
        if(min < max){
            randomnumber = uint(keccak256(abi.encodePacked(salt, blockhash(block.number - 1), blockhash(block.number - 2), blockhash(block.number - 3), 
            blockhash(block.number - 4), blockhash(block.number - 5), requestId ))) % (max - min + 1);
        } else {
            randomnumber = 0;
        }
        
        randomnumber = min + randomnumber;
        requestId += 1;
        return randomnumber;
    }


    function fullfillRandomness() external returns (uint256) {

        uint256 randomness; 
        
        randomness = uint256(keccak256(abi.encodePacked(
            requestId + block.timestamp + block.difficulty +
            ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (block.timestamp)) +
            block.gaslimit + 
            ((uint256(keccak256(abi.encodePacked(msg.sender)))) / (block.timestamp)) +
            block.number)));

        requestId += 1;

        return randomness;

    }
}
