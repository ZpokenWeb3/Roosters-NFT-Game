// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

import "utils/inter.sol";
import "interfaces/ichicken_nft.sol";
import "interfaces/iitem_nft.sol";
import "interfaces/ispell_nft.sol";
import "interfaces/irandomizer.sol";


contract Battle_Lib is Interconnected {


    enum ItemType {Weapon, Armor, Artefact, FemaleItem, ZombieItem}

     struct Settings {
         uint256 _FAIR_DIFF; // max difference in weighted parameters in %
         uint256 _ZODIAC_ITEM_BONUS; // % bonus to item effect when matching rooster zodiac
         uint256[5] FAIR_WEIGHTS; // Attack, defence, health, speed, luck
         uint256 ZODIAC_CARD_BUFF; // random card buff in case rooster zodiac match
         uint256 ZODIAC_CARD_DEBUFF; // random card debuff in case rooster zodiac does not match
         uint256 CRITICAL_THRESHOLD; // could be higher than 30 due to items
         uint256 CRITICAL_VALUE; // could be higher than 200 due to items
    }

    Settings settings = Settings({
        _FAIR_DIFF: 10,
        _ZODIAC_ITEM_BONUS: 15,
        FAIR_WEIGHTS: [uint256(100), uint256(37), uint256(125), uint256(47), uint256(38)],
        ZODIAC_CARD_BUFF: 5,
        ZODIAC_CARD_DEBUFF: 5,
        CRITICAL_THRESHOLD: 30,
        CRITICAL_VALUE: 100
    });

    struct Rooster {
        uint256 attack;
        uint256 defence;
        uint256 health;
        uint256 speed;
        uint256 luck;
        uint256 winsCounter;
        uint256 birthTime;
    }

    struct Item {
        ItemType itemType;
        uint256 selector;
        uint256 bonus;
        uint256 zodiac;
        uint256 requiredWins;
        bool vampiric;
    }

    struct RoundData {
        Rooster r1;
        Rooster r2;
        int256 hp_1;
        int256 hp_2;
        uint256 rnd_low_1;
        uint256 rnd_low_2;
        uint256 ankhItemId;
        uint256 crit_1;
        uint256 crit_2;
        uint256 spellBoost_1;
        uint256 spellWard_1;
        uint256 spellBoost_2;
        uint256 spellWard_2;
        uint256 sleepCounter_1;
        uint256 sleepCounter_2;
        bool weaponBreak;
        bool armorBreak;
        bool vampiricWeapon_1;
        bool vampiricWeapon_2;
        bool vampiricArmor_1;
        bool vampiricArmor_2;
   }

    // 0: _FAIR_DIFF, 1: _ZODIAC_ITEM_BONUS,2: ZODIAC_CARD_BUFF, 3: ZODIAC_CARD_DEBUFF,4: CRITICAL_THRESHOLD, 5: CRITICAL_VALUE
    /**
     * @dev Set settings for the contract
     * @dev zero values don't change anything
     * @return current settings
     */
    function setSettings(uint256 _FAIR_DIFF, uint256 _ZODIAC_ITEM_BONUS, uint256[5] memory fairWeights, uint256 ZODIAC_CARD_BUFF,
        uint256 ZODIAC_CARD_DEBUFF,uint256 CRITICAL_THRESHOLD,uint256 CRITICAL_VALUE) public onlyOwner returns(Settings memory){

        if (_FAIR_DIFF != 0 && settings._FAIR_DIFF != _FAIR_DIFF)
            {settings._FAIR_DIFF = _FAIR_DIFF;}
        if (_ZODIAC_ITEM_BONUS != 0 && settings._ZODIAC_ITEM_BONUS != _ZODIAC_ITEM_BONUS)
            {settings._ZODIAC_ITEM_BONUS = _ZODIAC_ITEM_BONUS;}
        for (uint8 i =0; i < 5; i++){
            if (fairWeights[i] != 0 && settings.FAIR_WEIGHTS[i] != fairWeights[i]){
                settings.FAIR_WEIGHTS[i] = fairWeights[i];
            }
        }
        if (ZODIAC_CARD_BUFF != 0 && settings.ZODIAC_CARD_BUFF != ZODIAC_CARD_BUFF)
            {settings.ZODIAC_CARD_BUFF = ZODIAC_CARD_BUFF;}
        if (ZODIAC_CARD_DEBUFF != 0 && settings.ZODIAC_CARD_DEBUFF != ZODIAC_CARD_DEBUFF)
            {settings.ZODIAC_CARD_DEBUFF = ZODIAC_CARD_DEBUFF;}
        if (CRITICAL_THRESHOLD != 0 && settings.CRITICAL_THRESHOLD != CRITICAL_THRESHOLD)
            {settings.CRITICAL_THRESHOLD = CRITICAL_THRESHOLD;}
        if (CRITICAL_VALUE != 0 && settings.CRITICAL_VALUE != CRITICAL_VALUE)
            {settings.CRITICAL_VALUE = CRITICAL_VALUE;}
        return settings;
    }

    // converting string of commands to array
    function getCommands(string memory commandString) external pure returns (string[] memory){
        string[] memory arrayCommands = new string[](6);
        uint8 counter = 0;
        uint8 attackCounter = 0;
        // convert string to bytes
        bytes memory b3 = bytes(commandString);
        // empty string of command = only attack
        if (b3.length == 0) {
            string[] memory onlyAttack = new string[](1);
            onlyAttack[0] = "A";
            return onlyAttack;
        }
        require(b3.length > 2, "Not enough commands!");
        require(b3.length <= 11, "Too many commands!");
        bytes1 attack = "A";
        bytes1 spell = "S";
        // parsing bytes to string and adding to string array
        for (uint i=0; i < b3.length; i++) {
            if (b3[i] == attack || b3[i] == spell){
                require(counter < 6, "Too many commands!");
                string memory converted;
                converted = bytes32ToString(b3[i]);
                arrayCommands[counter] = (converted);
                counter++;
                if (b3[i] == attack){
                    attackCounter++;
                }
            }
        }
        require(attackCounter >= 1, "There must be at least one attack!");
        // return dynamic array without empty commands
        string[] memory returnArray = new string[](counter);
        for (uint i=0; i < counter; i++) { 
            returnArray[i] = arrayCommands[i];
            }
        return returnArray;
    }

    // converting bytes to string
    function bytes32ToString(bytes32 _bytes32) internal pure returns (string memory) {
        uint8 i = 0;
        while(i < 32 && _bytes32[i] != 0) {
            i++;
        }
        bytes memory bytesArray = new bytes(i);
        for (i = 0; i < 32 && _bytes32[i] != 0; i++) {
            bytesArray[i] = _bytes32[i];
        }
        return string(bytesArray);
    }

    function checkSpell(string memory _command) external pure returns(bool){
        string memory spell = "S";
        string memory command = _command;
        if ((keccak256(abi.encodePacked((command))) == keccak256(abi.encodePacked((spell))))){
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Check if weighted parameters of roosters are within _FAIR_DIFF
     */
    function isFair(uint256[5] memory r1_array, uint256[5] memory r2_array) external view returns (bool) {
        // Fairness criteria is set by _FAIR_DIFF in percent
        uint256 sum1;
        uint256 sum2;
  
        sum1 = _getFairSum(r1_array);
        sum2 = _getFairSum(r2_array);

        // diff in percents
        if (sum1 >= sum2 ) {
            return 100 * (sum1 - sum2) / sum1 <= settings._FAIR_DIFF ? true : false;
        } else {
            return 100 * (sum2 - sum1) / sum1 <= settings._FAIR_DIFF ? true : false;
        }

    }

    function _getFairSum(uint256[5] memory rooster_array) public view returns (uint256 fairSum) {
        // Balancing parameters
        // only first 5 params are involved in calculation


        // calculating weighted sum
        for (uint256 i = 0; i < rooster_array.length; i++) {
            fairSum += settings.FAIR_WEIGHTS[i] * rooster_array[i];
        }
    }

    function fairSumForArenaQueue(uint256 roosterId, uint256[3] memory itemIds) external returns (uint256) {
        uint256[7] memory r_array;
        uint256[6] memory itemStats;

        r_array = IChicken_NFT(IAddressManager(addressManagerAddress).getAddress("chickenContractAddress")).getStats(roosterId);
        r_array = equipItems(r_array, itemIds);

        // negative effects become positive for himself to calculate valid Fair coefficient
        if (itemIds[2] != 0) {
                itemStats = IItem_NFT(IAddressManager(addressManagerAddress).getAddress("itemContractAddress")).getStats(itemIds[2]);
                if (itemStats[0] == 2 && itemStats[1] > 34 && itemStats[1] <= 50) {
                    // LUCK
                    r_array[4] += r_array[4] * itemStats[2] / 100;
                } else if (itemStats[0] == 2 && itemStats[1] > 83 && itemStats[1] <= 99) {
                    // SPEED
                    r_array[3] += r_array[3] * itemStats[2] / 100;
                }
        }

        return _getFairSum([r_array[0],r_array[1],r_array[2],r_array[3],r_array[4]]);

    }


    /**
     * @notice Converts UNIX timestamp to day of the week.
     * @dev 0 - Sunday
     * @param _timestamp block.timestamp UNIX timestamp 
     */
    function getZodiac(uint256 _timestamp) public pure returns (uint8) {
        return uint8((_timestamp / 86400 + 4) % 7);
    }


    function defineLowerRandomLimit(uint256 luck1, uint256 luck2) external pure returns (uint256 rand_low_1, uint256 rand_low_2) {
        if (luck1 >= luck2) {
            rand_low_1 = 80 + 20 * (luck1- luck2) / (luck1 - luck2 + 20);
            rand_low_2 = 160 - rand_low_1;
        } else {
            rand_low_2 = 80 + 20 * (luck2 - luck1) / (luck2 - luck1 + 20);
            rand_low_1 = 160 - rand_low_2;
        }
    }

    function chooseRandomSpell(uint256[3] memory spell_ids, uint256 _salt) external returns (uint256) {

        uint256 spellCounter;
        uint256[3] memory spellArray;
        uint256 randomNumber;

        for (uint256 i=0; i<3; i++) {
            if (spell_ids[i] != 0) {
                spellArray[spellCounter] = spell_ids[i];
                spellCounter++;
            }
        }

        if (spellCounter == 0) {
            return 0;
        } else if (spellCounter == 1) {
            return spellArray[0];
        } else {
            randomNumber = IRandomizer(IAddressManager(addressManagerAddress).getAddress("randomizerContractAddress")).getRandomInRange(0, spellCounter-1, _salt);
            return spellArray[randomNumber];
        }

    }

    /**
    * @dev apply negative effects to rooster parameters as array
    */
    function negativeEffects(uint256[7] memory enemyRooster, uint256[3] memory itemIds) external returns (uint256[7] memory) {
        uint256[6] memory itemStats;

        for (uint256 i=0; i<3; i++) {
            // negative effect for an enemy
            if (itemIds[i] != 0) {
                    itemStats = IItem_NFT(IAddressManager(addressManagerAddress).getAddress("itemContractAddress")).getStats(itemIds[i]);
                    if (itemStats[0] == 2 && itemStats[1] > 34 && itemStats[1] <= 50) {
                        // cruxes (luck--) (rooster[4])
                        enemyRooster[4] -= enemyRooster[4] * itemStats[2] / 100;
                    } else if (itemStats[0] == 2 && itemStats[1] > 83 && itemStats[1] <= 99) {
                        // decrease speed (rooster[3])
                        enemyRooster[3] -= enemyRooster[3] * itemStats[2] / 100;
                    }
            }
        }
        return enemyRooster;
    }
    
    
    /**
     * @dev Add items bonuses to rooster parameters as array
     */
    function equipItems(uint256[7] memory rooster, uint256[3] memory itemIds) public returns (uint256[7] memory) {
        uint256 param;
        uint256 bonus;

        for (uint256 i=0; i<3; i++) {
            
            // items are optional
            if (itemIds[i] != 0) {
                (param, bonus) = readItemBonus(itemIds[i], rooster);
                rooster[param] += bonus;
            }
        }
        return rooster;
    }

    
    function readItemBonus(uint256 _itemId, uint256[7] memory rooster) public returns (uint256, uint256) {

        uint256[6] memory itemStats;
        uint256 bonus;
        uint256 param;
        
        // 0 itemType; 1 selector; 2 bonus; 3 zodiac; 4 require wins; 5 vampiric;
        itemStats = IItem_NFT(IAddressManager(addressManagerAddress).getAddress("itemContractAddress")).getStats(_itemId);
        
        require(itemStats[4] <= rooster[5], "Rooster doesn't have enough wins for this Item!");

        bonus = itemStats[2];
        // % bonus to item effect when matching rooster zodiac
        if (itemStats[3] == getZodiac(rooster[6])) {
            bonus = ( bonus * (100 + settings._ZODIAC_ITEM_BONUS) ) / 100;
        }

        if (itemStats[0] == 0) {
            // Weapon
            param = 0;
        } else if (itemStats[0] == 1) {
            // Armor
            param = 1;
        } else if (itemStats[0] == 2 && itemStats[1] > 50 && itemStats[1] <= 67) {
            // HP++ rooster[2]
            param = 2;
            bonus = rooster[param] * bonus / 100;
        } else if (itemStats[0] == 2 && itemStats[1] > 18 && itemStats[1] <= 34) {
            // luck++ rooster[4]
            param = 4;
            bonus = rooster[param] * bonus / 100;
        } else if (itemStats[0] == 2 && itemStats[1] > 67 && itemStats[1] <= 83){
            //speed++ rooster[3]
            param = 3;
            bonus = rooster[param] * bonus / 100;
        } else {
            bonus = 0;
        }

        return (param, bonus);
    }

    // Checking spell items equip
    function readSpellBoostAndWard(uint256[3] memory itemIds) external returns(uint256, uint256){
        uint256[6] memory itemStats;
        
        uint256 spellItemBoost;
        uint256 spellItemWard;
        
        // only 3rd slot
        if (itemIds[2] != 0) {
            itemStats = IItem_NFT(IAddressManager(addressManagerAddress).getAddress("itemContractAddress")).getStats(itemIds[2]);
            if (itemStats[0] == 2 && itemStats[1] > 11 && itemStats[1] <= 18){
                spellItemBoost = itemStats[2];
            }
            if (itemStats[0] == 2 && itemStats[1] > 4 && itemStats[1] <= 11){
                spellItemWard = itemStats[2];
            }
        }
        return (spellItemBoost, spellItemWard);
    }

    function getRoundCriticals(RoundData memory _current) external returns(uint256 crit_1, uint256 crit_2) {
        // Critical attack (>100) and defence (<100), 100 - no criticals
        // Read max base Speed and Luck from chicken contract
        (uint256 max_speed, uint256 max_luck) = IChicken_NFT(IAddressManager(addressManagerAddress).getAddress("chickenContractAddress")).getMaxBaseStats();
        uint256 crit_1_threshold = settings.CRITICAL_THRESHOLD * _current.r1.luck / max_luck;
        uint256 crit_2_threshold = settings.CRITICAL_THRESHOLD * _current.r2.luck / max_luck;
        // Rooster 1 Attack Crit
        if (IRandomizer(IAddressManager(addressManagerAddress).getAddress("randomizerContractAddress")).getRandomInRange(1, 100, uint(_current.hp_1)) <= crit_1_threshold) {
            crit_1 = 100 + settings.CRITICAL_VALUE * _current.r1.speed / max_speed;
        } else {
            crit_1 = 100;
        }
        // Rooster 2 Attack Crit
        if (IRandomizer(IAddressManager(addressManagerAddress).getAddress("randomizerContractAddress")).getRandomInRange(1, 100, uint(_current.hp_2)) <= crit_2_threshold) {
            crit_2 = 100 + settings.CRITICAL_VALUE * _current.r2.speed / max_speed;
        } else {
            crit_2 = 100;
        }
        // Rooster 1 Defence Crit
        if (IRandomizer(IAddressManager(addressManagerAddress).getAddress("randomizerContractAddress")).getRandomInRange(1, 100, uint(_current.hp_1) + 1) <= crit_1_threshold) {
            if (crit_2 > 100) {crit_2 = 100;}
            else {crit_2 = 100 - settings.CRITICAL_VALUE * _current.r1.speed / (2 * max_speed);}
        }
        // Rooster 2 Defence Crit
        if (IRandomizer(IAddressManager(addressManagerAddress).getAddress("randomizerContractAddress")).getRandomInRange(1, 100, uint(_current.hp_2) + 1) <= crit_2_threshold) {
            if (crit_1 > 100) {crit_1 = 100;}
            else {crit_1 = 100 - settings.CRITICAL_VALUE * _current.r2.speed / (2 * max_speed);}
        }
    }

    function spellEffect(RoundData memory _current, uint256 spellId, 
        uint8 activeRooster, uint256 spellBoost, uint256 spellWard) 
        external returns (RoundData memory) {

        uint256[3] memory spell;
        uint256 selector;
        uint256 bonus;
        uint256 randomNumber;

        spell = ISpell_NFT(IAddressManager(addressManagerAddress).getAddress("spellContractAddress")).getStats(spellId);
        selector = spell[0];
        bonus = spell[1];

        bonus = (bonus * (100 + spellBoost - spellWard)) / 100;

        if (selector <= 5) {
            // sleep
            randomNumber = IRandomizer(IAddressManager(addressManagerAddress).getAddress("randomizerContractAddress")).getRandomInRange(1, 100, uint(_current.hp_1));
            if (randomNumber <= bonus) {
                if (activeRooster == 1) {_current.sleepCounter_2 = 2;} else {_current.sleepCounter_1 = 2;}
            }

        } else if (selector <= 20) {
            // heal
            if (activeRooster == 1) {_current.hp_1 = (_current.hp_1 * int(bonus + 100)) / 100;}
                else {_current.hp_2 = (_current.hp_2 * int(bonus + 100)) / 100;}
        } else if (selector <= 30) {
            // attack+
            if (activeRooster == 1) {_current.r1.attack = (_current.r1.attack * (bonus + 100)) / 100;} 
                else {_current.r2.attack = (_current.r2.attack * (bonus + 100)) / 100;}
        } else if (selector <= 40) {
            // defence+
            if (activeRooster == 1) {_current.r1.defence = (_current.r1.defence * (bonus + 100)) / 100;} 
                else {_current.r2.defence = (_current.r2.defence * (bonus + 100)) / 100;}
        } else if (selector <= 50) {
            // luck+
            if (activeRooster == 1) {_current.r1.luck = (_current.r1.luck * (bonus + 100)) / 100;} 
                else {_current.r2.luck = (_current.r2.luck * (bonus + 100)) / 100;}
        } else if (selector <= 60) {
            // speed+
            if (activeRooster == 1) {_current.r1.speed = (_current.r1.speed * (bonus + 100)) / 100;} 
                else {_current.r2.speed = (_current.r2.speed * (bonus + 100)) / 100;}
        } else if (selector <= 70) {
            // luck-
            if (activeRooster == 1) {_current.r2.luck = (_current.r2.luck * (100 - bonus)) / 100;} 
                else {_current.r1.luck = (_current.r1.luck * (100 - bonus)) / 100;}
        } else if (selector <= 80) {
            // attack-
            if (activeRooster == 1) {_current.r2.attack = (_current.r2.attack * (100 - bonus)) / 100;} 
                else {_current.r1.attack = (_current.r1.attack * (100 - bonus)) / 100;}
        } else if (selector <= 90) {
            // defence-
            if (activeRooster == 1) {_current.r2.defence = (_current.r2.defence * (100 - bonus)) / 100;} 
                else {_current.r1.defence = (_current.r1.defence * (100 - bonus)) / 100;}
        } else if (selector <= 100) {
            // speed-
            if (activeRooster == 1) {_current.r2.speed = (_current.r2.speed * (100 - bonus)) / 100;} 
                else {_current.r1.speed = (_current.r1.speed * (100 - bonus)) / 100;}
        }

        return _current;
    }
    
    function isAnkhEquipped(uint256 _itemId) external returns(uint256) { 

        uint256[6] memory itemStats;

        if (_itemId != 0) {
            itemStats = IItem_NFT(IAddressManager(addressManagerAddress).getAddress("itemContractAddress")).getStats(_itemId);
            if (itemStats[0] == 2 && itemStats[1] > 0 && itemStats[1] <= 4){
                return _itemId;
            }
        }
       
        return 0;
    }

    function roundCards(RoundData memory _current, 
        uint256[4] memory weaponsAndArmors, uint256 _salt) 
        external returns (RoundData memory, uint8) {

            uint256 randomNumber;
            uint8 cardNumber;
            uint8 randomZodiac;

            randomNumber = IRandomizer(IAddressManager(addressManagerAddress).getAddress("randomizerContractAddress")).getRandomInRange(1, 1000, _salt);

            // no blanc card unless repeated weapon or armor breaks
            if ( randomNumber <= 95) {
                // "att+"
                cardNumber = 1;
                _current.r1.attack = _current.r1.attack * 11 / 10;
                _current.r2.attack = _current.r2.attack * 11 / 10;
            } else if ( randomNumber <= 190) {
                // "def+"
                cardNumber = 2;
                _current.r1.defence = _current.r1.defence * 11 / 10;
                _current.r2.defence = _current.r2.defence * 11 / 10;
            } else if ( randomNumber <= 285) {
                // "hp+"
                cardNumber = 3;
                _current.hp_1 = _current.hp_1 * 11 / 10;
                _current.hp_2 = _current.hp_2 * 11 / 10;
            } else if ( randomNumber <= 380) {
                // "lck+"
                cardNumber = 4;
                _current.r1.luck = _current.r1.luck * 11 / 10;
                _current.r2.luck = _current.r2.luck * 11 / 10;
            } else if ( randomNumber <= 475) {
                // "att-"
                cardNumber = 5;
                _current.r1.attack = _current.r1.attack * 9 / 10;
                _current.r2.attack = _current.r2.attack * 9 / 10;
            } else if ( randomNumber <= 570) {
                // "def-"
                cardNumber = 6;
                _current.r1.defence = _current.r1.defence * 9 / 10;
                _current.r2.defence = _current.r2.defence * 9 / 10;
            } else if ( randomNumber <= 665) {
                // "speed+"
                cardNumber = 7;
                _current.r1.speed = _current.r1.speed * 11 / 10;
                _current.r2.speed = _current.r2.speed * 11 / 10;
            } else if ( randomNumber <= 760) {
                // "speed-"
                cardNumber = 8;
                _current.r1.speed = _current.r1.speed * 9 / 10;
                _current.r2.speed = _current.r2.speed * 9 / 10;
            } else if ( randomNumber <= 855) {
                // "Weapon break"
                if (!_current.weaponBreak) {

                    cardNumber = 9;
                    _current.r1.attack = _current.r1.attack - weaponsAndArmors[0];
                    _current.r2.attack = _current.r2.attack - weaponsAndArmors[1];

                    _current.weaponBreak = true;
                } // no card (cardNumber = 0) if break already happened

            } else if ( randomNumber <= 950) {
                // "Armor break"
                if (!_current.armorBreak) {
                    
                    cardNumber = 10;
                    _current.r1.defence = _current.r1.defence - weaponsAndArmors[2];
                    _current.r2.defence = _current.r2.defence - weaponsAndArmors[3];

                    _current.armorBreak = true;
                } // no card (cardNumber = 0) if break already happened

            } else if ( randomNumber <= 1000) {

                randomZodiac = uint8(IRandomizer(IAddressManager(addressManagerAddress).getAddress("randomizerContractAddress")).getRandomInRange(0, 6, _salt + 1));

                if ( randomNumber <= 975) {
                    // "Birthday card Positive" all stats +5% if same zodiac with random
                    cardNumber = 110 + randomZodiac;
                    if (getZodiac(_current.r1.birthTime) == randomZodiac) {
                        _current.r1.attack = _current.r1.attack * (100 + settings.ZODIAC_CARD_BUFF) / 100;
                        _current.r1.defence = _current.r1.defence * (100 + settings.ZODIAC_CARD_BUFF) / 100;
                        _current.hp_1 = _current.hp_1 * int(100 + settings.ZODIAC_CARD_BUFF) / 100;
                        _current.r1.speed = _current.r1.speed * (100 + settings.ZODIAC_CARD_BUFF) / 100;
                        _current.r1.luck = _current.r1.luck * (100 + settings.ZODIAC_CARD_BUFF) / 100;
                    }
                    if (getZodiac(_current.r2.birthTime) == randomZodiac) {
                        _current.r2.attack = _current.r2.attack * (100 + settings.ZODIAC_CARD_BUFF) / 100;
                        _current.r2.defence = _current.r2.defence * (100 + settings.ZODIAC_CARD_BUFF) / 100;
                        _current.hp_2 = _current.hp_2 * int(100 + settings.ZODIAC_CARD_BUFF) / 100;
                        _current.r2.speed = _current.r2.speed * (100 + settings.ZODIAC_CARD_BUFF) / 100;
                        _current.r2.luck = _current.r2.luck * (100 + settings.ZODIAC_CARD_BUFF) / 100;
                    }

                } else if ( randomNumber <= 1000) {
                    // "Birthday card Negative" all stats -5% unless same zodiac with random
                    cardNumber = 120 + randomZodiac;
                    if (getZodiac(_current.r1.birthTime) != randomZodiac) {
                        _current.r1.attack = _current.r1.attack * (100 - settings.ZODIAC_CARD_DEBUFF) / 100;
                        _current.r1.defence = _current.r1.defence * (100 - settings.ZODIAC_CARD_DEBUFF) / 100;
                        _current.hp_1 = _current.hp_1 * int(100 - settings.ZODIAC_CARD_DEBUFF) / 100;
                        _current.r1.speed = _current.r1.speed * (100 - settings.ZODIAC_CARD_DEBUFF) / 100;
                        _current.r1.luck = _current.r1.luck * (100 - settings.ZODIAC_CARD_DEBUFF) / 100;
                    }
                    if (getZodiac(_current.r2.birthTime) != randomZodiac) {
                        _current.r2.attack = _current.r2.attack * (100 - settings.ZODIAC_CARD_DEBUFF) / 100;
                        _current.r2.defence = _current.r2.defence * (100 - settings.ZODIAC_CARD_DEBUFF) / 100;
                        _current.hp_2 = _current.hp_2 * int(100 - settings.ZODIAC_CARD_DEBUFF) / 100;
                        _current.r2.speed = _current.r2.speed * (100 - settings.ZODIAC_CARD_DEBUFF) / 100;
                        _current.r2.luck = _current.r2.luck * (100 - settings.ZODIAC_CARD_DEBUFF) / 100;
                    }

                } 
            }
           
        return (_current, cardNumber);
    }

  
}

