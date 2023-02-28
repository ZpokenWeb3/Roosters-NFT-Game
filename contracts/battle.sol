// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

import "utils/inter.sol";
import "interfaces/ichicken_nft.sol";
import "interfaces/iitem_nft.sol";
import "interfaces/ispell_nft.sol";
import "interfaces/iarena_queue.sol";
import "interfaces/irandomizer.sol";
import "interfaces/ivault.sol";


abstract contract Battle_Data {

    struct Rooster {
        uint256 attack;
        uint256 defence;
        uint256 health;
        uint256 speed;
        uint256 luck;
        uint256 winsCounter;
        uint256 birthTime;
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

} 

abstract contract abs_Battle_Lib is Battle_Data {
    
    function checkSpell(string memory _command) virtual external pure returns(bool);
    function chooseRandomSpell(uint256[3] memory spell_ids, uint256 _salt) virtual external returns (uint256);
    function defineLowerRandomLimit(uint256 luck1, uint256 luck2) virtual external pure returns (uint256 rand_low_1, uint256 rand_low_2);
    function equipItems(uint256[7] memory rooster, uint256[3] memory itemIds) virtual external returns (uint256[7] memory);
    function fairSumForArenaQueue(uint256 roosterId, uint256[3] memory itemIds) virtual external returns (uint256);
    function getZodiac(uint256 _timestamp) virtual external pure returns (uint8);
    function getCommands(string memory commandString) virtual external pure returns (string[] memory);
    function getRoundCriticals(RoundData memory _current) virtual external returns(uint256 crit_1, uint256 crit_2);
    function isAnkhEquipped(uint256 _itemId) virtual external returns(uint256);
    function isFair(uint256[5] memory r1_array, uint256[5] memory r2_array) virtual external pure returns (bool);
    function negativeEffects(uint256[7] memory enemyRooster, uint256[3] memory itemIds) virtual external returns (uint256[7] memory);
    function readItemBonus(uint256 _itemId, uint256[7] memory rooster) virtual external returns (uint256, uint256);
    function readSpellBoostAndWard(uint256[3] memory itemIds) virtual external returns(uint256, uint256);
    function roundCards(RoundData memory _current, 
        uint256[4] memory weaponsAndArmors, uint256 _salt) 
        virtual external returns (RoundData memory, uint8);
    function spellEffect(RoundData memory _current, uint256 spellId, 
        uint8 activeRooster, uint256 spellBoost, uint256 spellWard) 
        virtual external returns (RoundData memory);

}

contract NFT_Rooster_Battle is Interconnected, Battle_Data {

    abs_Battle_Lib battleLib;
    
    enum ItemType {Weapon, Armor, Artefact, FemaleItem, ZombieItem}

    struct Settings {
        uint256 _FIGHT_DELAY; // betting window
        uint256 _TIME_LIMIT; // time limit for a fight before initiate
        uint256 VAMPIRIC_WEAPON; // reduce opponent def every hit
        uint256 VAMPIRIC_ARMOR; // reduce opponent atk every hit taken
        uint256 CANCEL_PRICE; // RHC, fee for cancel the battle
        uint256 ATTACK_THRESHOLD; // threshold of attack
        uint256 MIRROR_ADVANTAGE; // lower mirror rooster in %
    }

    Settings settings = Settings({
        _FIGHT_DELAY: 10 minutes,
        _TIME_LIMIT: 1 days,
        VAMPIRIC_WEAPON: 5,
        VAMPIRIC_ARMOR: 2,
        CANCEL_PRICE: 10 ether,
        ATTACK_THRESHOLD: 85,
        MIRROR_ADVANTAGE: 4
    });

    struct Item {
        ItemType itemType;
        uint256 selector;
        uint256 bonus;
        uint256 zodiac;
        uint256 requiredWins;
        bool vampiric;
    }

    struct FightData {
        uint256 stakeId1;
        uint256 stakeId2; 
        uint256 timestamp;
        uint256 winnerStakeId; // 0 - fight was not initiated
        uint256 loserStakeId; // new minted bones NFT id
    }

    struct FightStory {
            uint256 hp_1;
            uint256 hp_2;
            uint256 spell_id_1;
            uint256 spell_id_2;
            uint256 crit_1;
            uint256 crit_2;
            uint8 card;
        }

    struct StakeData {
        uint256 roosterId;
        uint256 fightId;
        uint256 timestamp;
        uint256[3] itemIds;
        uint256[3] spell_ids;
        address ownerAddress;
        string[] commands;
        bool isMirror;
    }


    uint256 internal fightCounter; // fight id, 0 is empty
    uint256 internal stakeCounter; // stake id, 0 is empty

    mapping(uint256 => FightData) internal fights;
    mapping(uint256 => StakeData) internal stakes;
    mapping(address => uint256[]) private userOwnedFights;
    mapping(address => uint256[]) private userOwnedStakes;

    address battleLibAddress;

    event FightEventRoosters(
        uint256 indexed fightId,
        uint256 rooster1Id,
        uint256 rooster2Id,
        Rooster Rooster1Equipped,
        Rooster Rooster2Equipped
    );

    event FightEvent(
        uint256 indexed fightId,
        uint256 winnerRoosterId,
        FightData fightData,
        FightStory[] fightStory
    );

    event FightCanceled(
        uint256 indexed fightId,
        uint256 timestamp
    );

    // event ErrorInQueue(string reason);

    constructor(address _battleLibAddress) {

        battleLib = abs_Battle_Lib(_battleLibAddress);
    }

    /**
     * @dev Set settings for the contract
     * @dev zero values don't change anything
     * @return current settings
     */
    function setSettings(uint256 _FIGHT_DELAY, uint256 _TIME_LIMIT, 
        uint256 VAMPIRIC_WEAPON, uint256 VAMPIRIC_ARMOR, 
        uint256 CANCEL_PRICE, uint256 ATTACK_THRESHOLD, uint256 MIRROR_ADVANTAGE) public onlyOwner returns (Settings memory){
        
        if (_FIGHT_DELAY != 0 && settings._FIGHT_DELAY != _FIGHT_DELAY) 
            {settings._FIGHT_DELAY = _FIGHT_DELAY;}
        if (_TIME_LIMIT != 0 && settings._TIME_LIMIT != _TIME_LIMIT) 
            {settings._TIME_LIMIT = _TIME_LIMIT;}
        if (VAMPIRIC_WEAPON != 0 && settings.VAMPIRIC_WEAPON != VAMPIRIC_WEAPON) 
            {settings.VAMPIRIC_WEAPON = VAMPIRIC_WEAPON;}
        if (VAMPIRIC_ARMOR != 0 && settings.VAMPIRIC_ARMOR != VAMPIRIC_ARMOR) 
            {settings.VAMPIRIC_ARMOR = VAMPIRIC_ARMOR;}
        if (CANCEL_PRICE != 0 && settings.CANCEL_PRICE != CANCEL_PRICE) 
            {settings.CANCEL_PRICE = CANCEL_PRICE;}
        if (ATTACK_THRESHOLD != 0 && settings.ATTACK_THRESHOLD != ATTACK_THRESHOLD) 
            {settings.ATTACK_THRESHOLD = ATTACK_THRESHOLD;}
        if (MIRROR_ADVANTAGE != 0 && settings.MIRROR_ADVANTAGE != MIRROR_ADVANTAGE) 
            {settings.MIRROR_ADVANTAGE = MIRROR_ADVANTAGE;}
        
        return settings;
    }

    // DEV Only!
    function getUserFights(address userAddress) public view returns (uint256[] memory) {

        uint256 userOwnedCounter;

        uint256[] memory tempArray = new uint256[](fightCounter+1);

        for (uint256 i=0; i<fightCounter+1; ++i) {
            if (stakes[fights[i].stakeId1].ownerAddress == userAddress 
                || stakes[fights[i].stakeId2].ownerAddress == userAddress) {

                tempArray[userOwnedCounter] = i;
                ++userOwnedCounter;
            }
        }
        // Static array to dynamic output array
        uint256[] memory userFights = new uint256[](userOwnedCounter);
        for (uint256 i=0; i<userOwnedCounter; ++i) {
            userFights[i] = tempArray[i];
        }

        return userFights;
        
    }

    // DEV Only!
    function getUserStakes(address userAddress) public view returns (uint256[] memory) {

        uint256 userOwnedCounter;

        uint256[] memory tempArray = new uint256[](stakeCounter+1);

        for (uint256 i=0; i<stakeCounter+1; ++i) {
            if (stakes[i].ownerAddress == userAddress) {

                tempArray[userOwnedCounter] = i;
                ++userOwnedCounter;
            }
        }
        // Static array to dynamic output array
        uint256[] memory userStakes = new uint256[](userOwnedCounter);
        for (uint256 i=0; i<userOwnedCounter; ++i) {
            userStakes[i] = tempArray[i];
        }

        return userStakes;
        
    }

       
    /**
     * @notice Stake a rooster for a fight
     * @param roosterId id of the rooster
     * @param itemIds array of items for the rooster (Weapon, Armor, Male item)
     * @return stakeId id of the successful stake
     */
    function stakeRooster(uint256 roosterId, uint256[3] memory itemIds, uint256[3] memory spell_ids, string memory commandString) public returns (uint256) {

        StakeData memory stakeData;
        uint256 fairSum;

        allAddresses.chickenContractAddress = IAddressManager(addressManagerAddress).getAddress("chickenContractAddress");
        allAddresses.itemContractAddress = IAddressManager(addressManagerAddress).getAddress("itemContractAddress");
        allAddresses.spellContractAddress = IAddressManager(addressManagerAddress).getAddress("spellContractAddress");

        require(IChicken_NFT(allAddresses.chickenContractAddress).isStaked(roosterId) == false, "Already staked!");
        require(IChicken_NFT(allAddresses.chickenContractAddress).ownerOf(roosterId) == msg.sender, "Rooster doesn't belong to sender!");

        for (uint256 i=0; i<3; i++) {
            if (itemIds[i] != 0) {

                require(IItem_NFT(allAddresses.itemContractAddress).isStaked(itemIds[i]) == false, "Item is already staked!");
                require(IItem_NFT(allAddresses.itemContractAddress).ownerOf(itemIds[i]) == msg.sender, "Item doesn't belong to sender!");
                // Weapon, Armor, Male item
                require(IItem_NFT(allAddresses.itemContractAddress).getStats(itemIds[i])[0] == i, "Incorrect item type in a slot!");
                // Set staked state for an item
                IItem_NFT(allAddresses.itemContractAddress).setStaked(itemIds[i], true);
            }
            if (spell_ids[i] != 0) {
                require(ISpell_NFT(allAddresses.spellContractAddress).isStaked(spell_ids[i]) == false, "Spell is already staked!");
                require(ISpell_NFT(allAddresses.spellContractAddress).ownerOf(spell_ids[i]) == msg.sender, "Spell doesn't belong to sender!");
                ISpell_NFT(allAddresses.spellContractAddress).setStaked(spell_ids[i], true);
            }
        }

        IChicken_NFT(allAddresses.chickenContractAddress).setStaked(roosterId, true);

        stakeData.roosterId = roosterId;
        stakeData.itemIds = itemIds;
        stakeData.spell_ids = spell_ids;
        stakeData.timestamp = block.timestamp;
        stakeData.commands = battleLib.getCommands(commandString);
        stakeData.ownerAddress = msg.sender;

        stakeCounter += 1;
        stakes[stakeCounter] = stakeData;

        // insert stake into arena queue with fair coefficient
        fairSum = battleLib.fairSumForArenaQueue(roosterId, itemIds);

        try IArena_Queue(IAddressManager(addressManagerAddress).getAddress("arenaContractAddress")).insertItem(stakeCounter, fairSum) 
            returns (uint removedId) {
            if (removedId != 0) {
                // remove oldest stake in the queue over max limit
                _unstakeRoosterAndItems(removedId);
            }
        } catch {}
        

        return stakeCounter;
    }

    function getStakeData(uint256 _stakeId) public view returns (StakeData memory) {
        return stakes[_stakeId];
    }

    /**
     * @notice Unstake a rooster and items
     * @dev only owner of the rooster may unstake
     * @param _stakeId id of the stake
     */
    function unstakeRoosterAndItems(uint256 _stakeId) public {

        require(stakes[_stakeId].ownerAddress == msg.sender, "Stake doesn't belong to sender!");
        require(stakes[_stakeId].fightId == 0, "Rooster is locked in a fight!");

        _unstakeRoosterAndItems(_stakeId);

        // remove stake id from Arena Queue
        IArena_Queue(IAddressManager(addressManagerAddress).getAddress("arenaContractAddress")).removeItem(_stakeId);
    }

    function _unstakeRoosterAndItems(uint256 _stakeId) internal {

        for (uint256 i=0; i<3; i++) {
            if (stakes[_stakeId].itemIds[i] != 0) {
                IItem_NFT(allAddresses.itemContractAddress).setStaked(stakes[_stakeId].itemIds[i], false);
            }
            if (stakes[_stakeId].spell_ids[i] != 0) {
                IItem_NFT(allAddresses.spellContractAddress).setStaked(stakes[_stakeId].spell_ids[i], false);
            }
        }

        IChicken_NFT(allAddresses.chickenContractAddress).setStaked(stakes[_stakeId].roosterId, false);

        // Keeping stakes history
        // delete stakes[_stakeId];
    }

    /**
     * @notice Set a rooster fight
     * @param stakeId1 id of the 1st rooster
     * @param stakeId2 id of the 2nd rooster
     * @return fightId 
     */
    function setFight(uint256 stakeId1, 
                      uint256 stakeId2) 
        public returns (uint256) {

        require(stakes[stakeId1].fightId == 0 && stakes[stakeId2].fightId == 0, "Already in a fight!");
        
        Rooster memory r1;
        Rooster memory r2;
        bool isFair;
        
        (r1, r2) = equipRoostersItems(stakeId1, stakeId2);

        isFair = battleLib.isFair(
            [r1.attack, r1.defence, r1.health, r1.speed, r1.luck],
            [r2.attack, r2.defence, r2.health, r2.speed, r2.luck]
            );

        require(isFair, "Fight is not fair!");

        FightData memory thisFightData;

        thisFightData.stakeId1 = stakeId1;
        thisFightData.stakeId2 = stakeId2;
        thisFightData.timestamp = block.timestamp;

        fightCounter += 1;
        stakes[stakeId1].fightId = fightCounter;
        stakes[stakeId2].fightId = fightCounter;
        fights[fightCounter] = thisFightData;

        return fightCounter;
    }

    function findOponentInArenaQueue(uint256 _stakeId) public returns (uint256) {
        uint256 _fightId;
        uint256 _stakeId2;
        uint256 _mirrorId;
        Rooster memory r1;
        Rooster memory r2;
        bool isFair;

        allAddresses.arenaContractAddress = IAddressManager(addressManagerAddress).getAddress("arenaContractAddress");

        _stakeId2 = IArena_Queue(allAddresses.arenaContractAddress).getNearestNeighbor(_stakeId);

        (r1, r2) = equipRoostersItems(_stakeId, _stakeId2);

        isFair = battleLib.isFair(
            [r1.attack, r1.defence, r1.health, r1.speed, r1.luck],
            [r2.attack, r2.defence, r2.health, r2.speed, r2.luck]
            );

        if (isFair) {
            _fightId = setFight(_stakeId, _stakeId2);
            // remove both stake ids from Arena Queue
            IArena_Queue(allAddresses.arenaContractAddress ).removeItem(_stakeId);
            IArena_Queue(allAddresses.arenaContractAddress ).removeItem(_stakeId2);
        } else {
            _mirrorId = _createMirrorStake(r1);
            // setting a fight
            _fightId = setFight(_stakeId, _mirrorId);
            IArena_Queue(allAddresses.arenaContractAddress ).removeItem(_stakeId);
        }

        return _fightId;
    }

    function _createMirrorStake(Rooster memory r1) internal returns (uint256) {
        // MIRROR FIGHT
        // mint mirror rooster
        uint256 _mirrorId;

        address chickenContractAddress = IAddressManager(addressManagerAddress).getAddress("chickenContractAddress");

        _mirrorId = IChicken_NFT(chickenContractAddress).mintMirror(
            [r1.attack * (100 - settings.MIRROR_ADVANTAGE) / 100 + 1, 
            r1.defence * (100 - settings.MIRROR_ADVANTAGE) / 100 + 1, 
            r1.health * (100 - settings.MIRROR_ADVANTAGE) / 100 + 1, 
            r1.speed * (100 - settings.MIRROR_ADVANTAGE) / 100 + 1, 
            r1.luck * (100 - settings.MIRROR_ADVANTAGE) / 100 + 1]);
        // staking
        stakeCounter += 1;
        stakes[stakeCounter].roosterId = _mirrorId;
        stakes[stakeCounter].timestamp = block.timestamp;
        stakes[stakeCounter].commands = ["A","A"];
        stakes[stakeCounter].ownerAddress = address(1);
        stakes[stakeCounter].isMirror = true;

        return stakeCounter;
    }

    function fightNow(uint256 roosterId, uint256[3] memory itemIds, uint256[3] memory spell_ids, string memory commandString) public {
        Rooster memory r1;
        settings._FIGHT_DELAY = 0;

        uint256 _stakeId = stakeRooster( roosterId, itemIds, spell_ids, commandString);
        (r1, r1) = equipRoostersItems(_stakeId, _stakeId);
        uint256 _mirrorId = _createMirrorStake(r1);
        // setting a fight
        uint256 _fightId = setFight(_stakeId, _mirrorId);
        uint256 winnerRoosterId = initiateFightWithSeed(_fightId, uint256(keccak256(abi.encodePacked(msg.sender))));

        // Win reward for DEMO
        if(winnerRoosterId == roosterId){
            IRHC_Vault(IAddressManager(addressManagerAddress).getAddress("vaultContractAddress")).rewardAccount(msg.sender, r1.luck * 1 ether);
        }
        
    }

    /**
     * @notice Cancel a fight before initiate
     * @dev fight may be canceled free of charge by anyone if expired
     * @dev only rooster owners may cancel the fight before expire time limit
     * @param _fightId id of the fight
     */
    function cancelFight(uint256 _fightId) public {

        bool paymentDone;

        require(fights[_fightId].timestamp > 0, "There is no such fight!");
        
        // only unfinished fights may be canceled
        require(fights[_fightId].winnerStakeId == 0, "Fight is already finished!");

        // fight may be canceled free of charge by anyone if expired
        if (block.timestamp >= fights[_fightId].timestamp + settings._TIME_LIMIT) {
            _cancelFight(_fightId);
            return;
        }

        // only rooster owners may cancel the fight before expire time limit
        require(
            stakes[fights[_fightId].stakeId1].ownerAddress == msg.sender || 
            stakes[fights[_fightId].stakeId2].ownerAddress == msg.sender, 
            "Stake in a fight doesn't belong to sender!"
            );

        // before expire time limit fight may be canceled for a cancelPrice by rooster owners

        paymentDone = IRHC_Vault(IAddressManager(addressManagerAddress).getAddress("vaultContractAddress")).makePayment(msg.sender, settings.CANCEL_PRICE);
        require(paymentDone, "Payment Error!");

        _cancelFight(_fightId);
    }

    function _cancelFight(uint256 _fightId) private {

        // release stakes from a fight
        uint256 stakeId1 = fights[_fightId].stakeId1;
        uint256 stakeId2 = fights[_fightId].stakeId2;
        stakes[stakeId1].fightId = 0;
        stakes[stakeId2].fightId = 0;

        delete fights[_fightId];

        emit FightCanceled(_fightId, block.timestamp);
    }

    /**
     * @dev returns FightData (uint256 stakeId1, uint256 stakeId2, uint256 timestamp, uint256 winnerStakeId, uint256 looserId)
     */
    function getFightData(uint256 _fightId) public view returns (FightData memory) {

        return fights[_fightId];
    } 

    function readWeaponsAndArmors(uint256[3] memory items1, uint256[3] memory items2) internal returns (uint256[4] memory) {

        uint256[4] memory weaponsAndArmors;
        uint256[7] memory _roosterArray;

        // rooster stats are not needed for weapon and armor

        _roosterArray = [uint256(0), 0, 0, 0, 0, 100, 0];

        ( , weaponsAndArmors[0]) = battleLib.readItemBonus(items1[0], _roosterArray);
        ( , weaponsAndArmors[1]) = battleLib.readItemBonus(items2[0], _roosterArray);
        ( , weaponsAndArmors[2]) = battleLib.readItemBonus(items1[1], _roosterArray);
        ( , weaponsAndArmors[3]) = battleLib.readItemBonus(items2[1], _roosterArray);

        return weaponsAndArmors;
    }


    function getIndex(uint256 _element, uint256 _stakeId) internal view returns (string memory) {
        return stakes[_stakeId].commands[(_element) % stakes[_stakeId].commands.length];
    }

    
    //  * @return winnerStakeId id of the winner stake
    //  * @return whoFirst first rooster to attack out of 2 participants (1 or 2)
    //  * @return counterRounds number of rounds in a fight
    //  * @return fightStory history of (hp_1, hp_2, card) for all rounds
    /**
     * @notice Initiate a fight
     * @dev _FIGHT_DELAY time must pass after setFight, but no more than _TIME_LIMIT
     * @param _fightId id of the fight to initiate
     */
     function initiateFight(uint256 _fightId) public 
        returns (uint256)  
        {
        
        return initiateFightWithSeed(_fightId, uint256(keccak256(abi.encodePacked(msg.sender))));

        }

    function initiateFightWithSeed(uint256 _fightId, uint256 _seed) public 
        returns (uint256) 
        {
        
        FightStory[20] memory fightStory20;
        uint256 ankhItemId;
        uint256 counterRounds;
        uint256 winnerStakeId;
        uint256 loserStakeId;
        uint256 winnerRoosterId;
        
        require(fights[_fightId].timestamp > 0, "There is no such fight!");

        require(block.timestamp >= fights[_fightId].timestamp + settings._FIGHT_DELAY, "Too soon to initiate!");

        if (block.timestamp >= fights[_fightId].timestamp + settings._TIME_LIMIT) {
            _cancelFight(_fightId);
            // FightStory[] memory fightStoryEmpty = new FightStory[](1);
            // return (0, 0, 0, fightStoryEmpty);
        }

        (winnerStakeId, loserStakeId, counterRounds, fightStory20) = _calculateFightWithSeed(_fightId, _seed);

        fights[_fightId].winnerStakeId = winnerStakeId;
        fights[_fightId].loserStakeId = loserStakeId;

        // Static array to dynamic output array
        FightStory[] memory fightStory = new FightStory[](counterRounds);
        for (uint i = 0; i < counterRounds; i++) {
            fightStory[i] = fightStory20[i];
        }

        winnerRoosterId = stakes[winnerStakeId].roosterId;
        // increment wins counter of the winner rooster
        IChicken_NFT(IAddressManager(addressManagerAddress).getAddress("chickenContractAddress")).plusOneWinsCounter(winnerRoosterId);

        // turn loser rooster to bones NFT OR burn Ankh of Ressurection
        ankhItemId = battleLib.isAnkhEquipped(stakes[loserStakeId].itemIds[2]);
        roosterToBones(ankhItemId, loserStakeId);
        
        //unstake roosters and items
        _unstakeRoosterAndItems(winnerStakeId);
        _unstakeRoosterAndItems(loserStakeId);

        emit FightEvent(_fightId, winnerRoosterId, fights[_fightId], fightStory);

        return winnerRoosterId;

    }

    function simulateFightWithSeed(uint256 _fightId, uint256 _seed) public onlyOwner
        returns (uint256 winnerStakeId) { 
            (winnerStakeId,,,) = _calculateFightWithSeed(_fightId, _seed);
        }

    function _calculateFightWithSeed(uint256 _fightId, uint256 _seed) internal 
        returns (uint256 winnerStakeId, uint256 loserStakeId, 
                 uint256 counterRounds,
                 FightStory[20] memory fightStory) {

        uint256 whoFirst;
        RoundData memory current;
        
        allAddresses.randomizerContractAddress = IAddressManager(addressManagerAddress).getAddress("randomizerContractAddress");

        // Weapon and Armor breaks may happen only 1 time per battle
        uint256[4] memory weaponsAndArmors;
        weaponsAndArmors = readWeaponsAndArmors(
            stakes[fights[_fightId].stakeId1].itemIds, 
            stakes[fights[_fightId].stakeId2].itemIds);
        
        (current.r1, current.r2) = equipRoostersItems(fights[_fightId].stakeId1, fights[_fightId].stakeId2);

        emit FightEventRoosters(_fightId, stakes[fights[_fightId].stakeId1].roosterId, 
            stakes[fights[_fightId].stakeId2].roosterId, current.r1, current.r2);

        current.hp_1 = 2 * int256(current.r1.health);
        current.hp_2 = 2 * int256(current.r2.health);
        (current.spellBoost_1, current.spellWard_1) = 
            battleLib.readSpellBoostAndWard(stakes[fights[_fightId].stakeId1].itemIds);
        (current.spellBoost_2, current.spellWard_2) = 
            battleLib.readSpellBoostAndWard(stakes[fights[_fightId].stakeId2].itemIds);
    
        while (current.hp_1 >= 0 && current.hp_2 >= 0) {
            fightStory[counterRounds].hp_1 = uint256(current.hp_1);
            fightStory[counterRounds].hp_2 = uint256(current.hp_2);

            counterRounds += 1;

            // Playing cards for a round
            (current, fightStory[counterRounds-1].card) = battleLib.roundCards(current, weaponsAndArmors, 
                uint256(keccak256(abi.encodePacked(_seed))) + counterRounds);

            // Determine who is first to strike
            whoFirst = defineFirstRooster(current.r1.speed, current.r2.speed, 
                uint256(keccak256(abi.encodePacked(_seed))) + counterRounds + 1);

            // Determine lower limits of attack
            (current.rnd_low_1, current.rnd_low_2) = 
                battleLib.defineLowerRandomLimit(current.r1.luck, current.r2.luck);

            // Critical attack (>100) and defence (<100), 100 - no criticals
            (current.crit_1, current.crit_2) = battleLib.getRoundCriticals(current);

            // ROOSTER 1 Phase
            // Check sleep
            if (current.sleepCounter_1 == 0) {
                // Checking spell logic
                if (battleLib.checkSpell(getIndex((counterRounds - 1), fights[_fightId].stakeId1))){
                    // choose random spell
                    fightStory[counterRounds - 1].spell_id_1 = 
                        battleLib.chooseRandomSpell(stakes[fights[_fightId].stakeId1].spell_ids, 
                        uint256(keccak256(abi.encodePacked(_seed))) + counterRounds + 2);
                    
                    // calculate spell effect
                    current = battleLib.spellEffect(current, fightStory[counterRounds - 1].spell_id_1, 1, 
                        current.spellBoost_1, current.spellWard_2);

                } else {
                    current.hp_2 -= roundDamage(current.r1.attack, current.r2.defence, current.rnd_low_1,
                        uint256(keccak256(abi.encodePacked(_seed))) + counterRounds + 3) * int(current.crit_1) / 100;
                    // fightStory[counterRounds - 1].spell_id_1 = 0;
                    fightStory[counterRounds - 1].crit_1 = current.crit_1;
                    // Vampiric
                    if (current.vampiricWeapon_1 && !current.weaponBreak) {current.r2.defence = current.r2.defence * (100 - settings.VAMPIRIC_WEAPON) / 100;}
                    if (current.vampiricArmor_2 && !current.armorBreak) {current.r1.attack = current.r1.attack * (100 - settings.VAMPIRIC_ARMOR) / 100;}
                } 
            } else {current.sleepCounter_1 -= 1;}

            // ROOSTER 2 Phase
            // Check sleep
            if (current.sleepCounter_2 == 0) {
                // Checking spell logic
                if (battleLib.checkSpell(getIndex((counterRounds - 1), fights[_fightId].stakeId2))){
                    // choose random spell
                    fightStory[counterRounds - 1].spell_id_2 = 
                        battleLib.chooseRandomSpell(stakes[fights[_fightId].stakeId2].spell_ids,
                        uint256(keccak256(abi.encodePacked(_seed))) + counterRounds + 4);
                    // calculate spell effect
                    current = battleLib.spellEffect(current, fightStory[counterRounds - 1].spell_id_2, 2, 
                        current.spellBoost_2, current.spellWard_1);

                } else {
                    current.hp_1 -= roundDamage(current.r2.attack, current.r1.defence, current.rnd_low_2,
                        uint256(keccak256(abi.encodePacked(_seed))) + counterRounds + 5) * int(current.crit_2) / 100;
                    // fightStory[counterRounds - 1].spell_id_2 = 0;
                    fightStory[counterRounds - 1].crit_2 = current.crit_2;
                    // Vampiric
                    if (current.vampiricWeapon_2 && !current.weaponBreak) {current.r1.defence = current.r1.defence * (100 - settings.VAMPIRIC_WEAPON) / 100;}
                    if (current.vampiricArmor_1 && !current.armorBreak) {current.r2.attack = current.r2.attack * (100 - settings.VAMPIRIC_ARMOR) / 100;}
                }
            } else {current.sleepCounter_2 -= 1;}
            

            // Poison Cloud - force kill
            // Finish a fight in under 20 rounds
            if (current.r1.health >= current.r2.health && counterRounds < 21) {
                current.hp_1 -= 2 * int256(current.r1.health) / int256(21 - counterRounds);
                current.hp_2 -= 2 * int256(current.r1.health) / int256(21 - counterRounds);
            } else {
                current.hp_1 -= 2 * int256(current.r2.health) / int256(21 - counterRounds);
                current.hp_2 -= 2 * int256(current.r2.health) / int256(21 - counterRounds);
            }
            
        }

        if (current.hp_2 <= 0 && whoFirst == 1 || current.hp_1 > 0) {
            winnerStakeId = fights[_fightId].stakeId1;
            loserStakeId = fights[_fightId].stakeId2;
        } else {
            winnerStakeId = fights[_fightId].stakeId2;
            loserStakeId = fights[_fightId].stakeId1;
        }

    }

    function roosterToBones (uint256 ankhItemId, uint256 loserStakeId) internal returns(uint256) {
        uint256 bonesQuality;
        if (ankhItemId != 0) {
            IItem_NFT(IAddressManager(addressManagerAddress).getAddress("itemContractAddress")).setStaked(ankhItemId,false);
            IItem_NFT(IAddressManager(addressManagerAddress).getAddress("itemContractAddress")).burnItemNft(ankhItemId);
        } else {
	        bonesQuality = IChicken_NFT(IAddressManager(addressManagerAddress).getAddress("chickenContractAddress")).roosterToBones(stakes[loserStakeId].roosterId);
	    }
        return bonesQuality;
    }

    /**
    * @dev read from array to Rooster struct
    */
    function readRoosterFromArray(uint256[7] memory roosterArray) internal pure returns (Rooster memory rooster) {

        rooster = Rooster(roosterArray[0], roosterArray[1], 
                            roosterArray[2], roosterArray[3], 
                            roosterArray[4], roosterArray[5], 
                            roosterArray[6]);

    }


    function equipRoostersItems(uint256 stakeId1, uint256 stakeId2 ) internal returns (Rooster memory r1, Rooster memory r2) {
        uint256[7] memory r1_array;
        uint256[7] memory r2_array;

        address chickenContractAddress;
        chickenContractAddress = IAddressManager(addressManagerAddress).getAddress("chickenContractAddress");

        // reading roosters as arrays
        r1_array = IChicken_NFT(chickenContractAddress).getStats(stakes[stakeId1].roosterId);
        r2_array = IChicken_NFT(chickenContractAddress).getStats(stakes[stakeId2].roosterId);
        // add all item bonuses to roosters stats
        r1_array = battleLib.equipItems(r1_array, stakes[stakeId1].itemIds);
        r2_array = battleLib.equipItems(r2_array, stakes[stakeId2].itemIds);
        // apply negative effects;
        r1_array = battleLib.negativeEffects(r1_array, stakes[stakeId2].itemIds);
        r2_array = battleLib.negativeEffects(r2_array, stakes[stakeId1].itemIds);

        r1 = readRoosterFromArray(r1_array);
        r2 = readRoosterFromArray(r2_array);

    }

    /**
    * @dev who strikes first out of 2 roosters (1 or 2)
    * @return whoFirst 1 or 2 - 1st or 2nd rooster
    */
    function defineFirstRooster(uint256 speed1, uint256 speed2, uint256 _salt) internal returns (uint256 whoFirst) {


        if (speed1 >= speed2) {
            whoFirst = 1 + IRandomizer(allAddresses.randomizerContractAddress).getRandomInRange(1,100, _salt + 1) / 
                        (50 + (40 * (speed1 - speed2) / (speed1 - speed2 + 10)));
        } else {
            whoFirst = 1 + IRandomizer(allAddresses.randomizerContractAddress).getRandomInRange(1,100, _salt + 1) / 
                        (50 - (40 * (speed2 - speed1) / (speed2 - speed1 + 10)));
        }
        if (whoFirst > 2) { whoFirst = 2;}
    }


    function roundDamage(uint256 attack, uint256 defence, uint256 rand_low, uint256 _salt) internal returns (int256 damage) {
        damage = int256(attack * IRandomizer(allAddresses.randomizerContractAddress).getRandomInRange(rand_low, 125, attack + defence + _salt) * (100 - settings.ATTACK_THRESHOLD * defence /(defence + 20)) /10000) + 1;
    }



}