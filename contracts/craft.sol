// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "utils/inter.sol";
import "interfaces/ichicken_nft.sol";
import "interfaces/iitem_nft.sol";
import "interfaces/ispell_nft.sol";
import "interfaces/irandomizer.sol";
import "interfaces/ivault.sol";

contract Craft is Interconnected {

    struct Settings{
        uint256 SAME_TYPE_BONUS; // same type mix bonus
        uint256 WINS_BONUS; // roosters wins bonus to quality in percents
        uint256 SACRIFICE_BONUS; // bonus to item from chicken quality
    }

    Settings settings = Settings({
        SAME_TYPE_BONUS: 50,
        WINS_BONUS: 10,
        SACRIFICE_BONUS: 25
    });

    /**
     * @dev Set settings for the contract
     * @dev zero values don't change anything
     * @return current settings
     */
    function setSettings(uint256 SAME_TYPE_BONUS, uint256 WINS_BONUS, uint256 SACRIFICE_BONUS) public onlyOwner 
    returns (Settings memory) {
        if (SAME_TYPE_BONUS != 0 && settings.SAME_TYPE_BONUS != SAME_TYPE_BONUS) {settings.SAME_TYPE_BONUS = SAME_TYPE_BONUS;}
        if (WINS_BONUS != 0 && settings.WINS_BONUS != WINS_BONUS) {settings.WINS_BONUS = WINS_BONUS;}
        if (SACRIFICE_BONUS != 0 && settings.SACRIFICE_BONUS != SACRIFICE_BONUS) {settings.SACRIFICE_BONUS = SACRIFICE_BONUS;}

        return settings;
    }

    function mixWithMintSprig(uint256 itemId, uint256 sprigId) public {
        uint256[6] memory mintSprigStats;
        uint256[6] memory itemStats;
        uint256 random_number;

        address itemContractAddress = IAddressManager(addressManagerAddress).getAddress("itemContractAddress");

        // owner check
        require(IItem_NFT(itemContractAddress).ownerOf(itemId) == msg.sender 
            && IItem_NFT(itemContractAddress).ownerOf(sprigId) == msg.sender, "Item does not belong to sender!");

        // type check
        mintSprigStats = IItem_NFT(itemContractAddress).getStats(sprigId);
        require(mintSprigStats[0] == 2 && mintSprigStats[1] == 100, "Not a Mint Sprig!");

        itemStats = IItem_NFT(itemContractAddress).getStats(itemId);

        random_number = IRandomizer(IAddressManager(addressManagerAddress).getAddress("randomizerContractAddress")).getRandomInRange(1, 100, uint256(keccak256(abi.encodePacked(msg.sender))));

        if (random_number <= mintSprigStats[2]) {
            // LEVEL UP
            IItem_NFT(itemContractAddress).craftWithSprig(itemId, true, mintSprigStats[2], sprigId);
        } else {
            // BONUS UP
            IItem_NFT(itemContractAddress).craftWithSprig(itemId, false, mintSprigStats[2], sprigId);
        }

    }

    function mixWeaponOrArmor(uint256 mainItemId, uint256 burnItemId) public {
        uint256[6] memory mainStats;
        uint256[6] memory burnStats;

        // owner check
        require(IItem_NFT(IAddressManager(addressManagerAddress).getAddress("itemContractAddress")).ownerOf(mainItemId) == msg.sender 
            && IItem_NFT(IAddressManager(addressManagerAddress).getAddress("itemContractAddress")).ownerOf(burnItemId) == msg.sender, 
            "Item does not belong to sender!");

        mainStats = IItem_NFT(IAddressManager(addressManagerAddress).getAddress("itemContractAddress")).getStats(mainItemId);
        burnStats = IItem_NFT(IAddressManager(addressManagerAddress).getAddress("itemContractAddress")).getStats(burnItemId);

        // type check
        require(mainStats[0] == 0 || mainStats[0] == 1, "1st item not a weapon or armor!");
        require(burnStats[0] == 0 || burnStats[0] == 1, "2nd item not a weapon or armor!");
        require(mainStats[0] == burnStats[0], "Only same type!");

        IItem_NFT(IAddressManager(addressManagerAddress).getAddress("itemContractAddress")).craftMixSameType(mainItemId, settings.SAME_TYPE_BONUS, burnItemId);

    }

    function mixSacrificeChicken(uint256 mainItemId, uint256 burnChickenId) public {
        uint256[6] memory mainStats;
        uint256 addedBonus;

        // owner check
        require(IItem_NFT(IAddressManager(addressManagerAddress).getAddress("itemContractAddress")).ownerOf(mainItemId) == msg.sender 
            && IChicken_NFT(IAddressManager(addressManagerAddress).getAddress("chickenContractAddress")).ownerOf(burnChickenId) == msg.sender, 
            "Item does not belong to sender!");

        mainStats = IItem_NFT(IAddressManager(addressManagerAddress).getAddress("itemContractAddress")).getStats(mainItemId);

        // type check
        require(mainStats[0] == 0 || mainStats[0] == 1, "Only weapon or armor!");

        addedBonus = settings.SACRIFICE_BONUS * _readChickenBonus(burnChickenId) / 100 + 1;

        // Burn Sacrifice Chicken
        IChicken_NFT(IAddressManager(addressManagerAddress).getAddress("chickenContractAddress")).craftSacrifice(burnChickenId);

        // update item bonus
        IItem_NFT(IAddressManager(addressManagerAddress).getAddress("itemContractAddress")).craftItemLiveSacrifice(mainItemId, addedBonus);
    }

    function mixDoubleSacrifice(uint256 chickenId1, uint256 chickenId2) public returns (uint256 newItemId) {

        uint256 bonus1;
        uint256 bonus2;
        uint256 type1;
        uint256 type2;
        uint256 itemType;

        address chickenContractAddress = IAddressManager(addressManagerAddress).getAddress("chickenContractAddress");

        // owner check
        require(IChicken_NFT(chickenContractAddress).ownerOf(chickenId1) == msg.sender 
            && IChicken_NFT(chickenContractAddress).ownerOf(chickenId2) == msg.sender, 
            "Chicken does not belong to sender!");
        
        bonus1 = _readChickenBonus(chickenId1);
        bonus2 = _readChickenBonus(chickenId2);
        // {Rooster, Hen, Bones, Zombie}
        type1 = IChicken_NFT(chickenContractAddress).getType(chickenId1);
        type2 = IChicken_NFT(chickenContractAddress).getType(chickenId2);
        
        if (type1 == 0 && type2 == 0) {
            itemType = 0; // rooster + rooster -> weapon
        } else if (type1 == 1 && type2 == 1) {
            itemType = 1; // hen + hen -> armor
        } else {
            itemType = 2; // all other combos -> artefact - male item
        }

        // Burn Sacrifice Chickens
        IChicken_NFT(chickenContractAddress).craftSacrifice(chickenId1);
        IChicken_NFT(chickenContractAddress).craftSacrifice(chickenId2);

        // create new item
        newItemId = IItem_NFT(IAddressManager(addressManagerAddress).getAddress("itemContractAddress")).craftNewItem(msg.sender, bonus1 + bonus2, itemType);

    }

    function _readChickenBonus(uint256 _chickenId) internal view returns (uint256 chickenBonus) {

        uint256[7] memory chickenStats;

        chickenStats = IChicken_NFT(IAddressManager(addressManagerAddress).getAddress("chickenContractAddress")).getStats(_chickenId);
        chickenBonus = chickenStats[0]; // quality
        // rooster special case with wins
        if (chickenStats[1] != 0) {
            chickenBonus = (chickenStats[0] + chickenStats[1] + chickenStats[2] + chickenStats[3] + chickenStats[4]) / 5;
            // wins
            chickenBonus = chickenBonus * (100 + settings.WINS_BONUS * chickenStats[5] ) / 100;
        }
    }

        
}