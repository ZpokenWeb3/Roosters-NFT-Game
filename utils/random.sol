// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

library Random {

    function getRandomInRange(uint256 min, uint256 max, uint256 salt) internal view returns (uint) {
        uint randomnumber;
        if(min < max){
            randomnumber = uint(keccak256(abi.encodePacked(salt, blockhash(block.number - 1), blockhash(block.number - 2), blockhash(block.number - 3), 
            blockhash(block.number - 4), blockhash(block.number - 5), blockhash(block.number - 6), blockhash(block.number - 7), blockhash(block.number - 8), blockhash(block.number - 9), blockhash(block.number - 10) ))) % (max - min + 1);
        } else {
            randomnumber = 0;
        }
        
        randomnumber = min + randomnumber;
        return randomnumber;
    }
}