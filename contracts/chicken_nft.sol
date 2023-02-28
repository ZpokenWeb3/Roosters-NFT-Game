// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import "utils/inter.sol";
import "interfaces/iegg_nft.sol";
import "interfaces/iitem_nft.sol";
import "interfaces/irandomizer.sol";
import "interfaces/ivault.sol";

contract Chicken_NFT is ERC1155, Interconnected, Pausable {

    uint256 internal chickenCounter;
    uint256 internal henHouseCounter;
    uint256 internal testCounter;

    enum Entity {Rooster, Hen, Bones, Zombie}

    struct Settings {
        uint256 _BOOST_BREED; // boosting breed eggs ceiling, will be divided by 100
        uint256 _MAX_EGGS; // maximum number of eggs produced while staked (hen house cycles)
        uint256 _MAX_STAKES; // maximum number of active hen houses that produce eggs per user
        uint256 _WIN_BOOST; // every rooster win adds 10 to egg quality
        uint256 _REZ_TIME; // time limit of ressurection
        uint256 lifespan;
        uint256 peakDelay;
        uint256 peakRise; // percents
        uint256 henHouseCycle;
        uint256 rezPrice; // 18 decimals RHC
        uint256 BURN_REWARD;
    }


    Settings settings = Settings({
        _BOOST_BREED: 220,
        _MAX_EGGS: 3,
        _MAX_STAKES: 3,
        _WIN_BOOST: 10,
        _REZ_TIME: 1 hours,
        lifespan: 182 days,
        peakDelay: 14 days,
        peakRise: 20, // percents
        henHouseCycle: 10 minutes,
        rezPrice: 50 ether, // 50 RHC
        BURN_REWARD: 0.5 ether
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

    struct Hen {
        uint256 fertility;
        uint256 birthTime;
    }

    struct Bones {
        uint256 quality;
        uint256 deathTime;
    }

    struct Zombie{
        uint256 attack;
        uint256 defence;
        uint256 health;
        uint256 speed;
        uint256 luck;
        uint256 winsCounter;
        uint256 birthTime;
    }
    
    struct HenHouse {
        uint256 roosterId;
        uint256 henId;
        uint256 femaleItemId;
        uint256 createTime;
    }

    // Contract-wide max parameters for BASE stats
    // used for critical thresholds
    struct MaxBaseStats {
        uint256 maxBaseSpeed;
        uint256 maxBaseLuck;
    }

    MaxBaseStats internal maxBaseStats;

    mapping(uint256 => address) private _ownerOf;
    mapping(address => uint256[]) private userOwnedIds;
    mapping(uint256 => Entity) public tokenIdToType;
    mapping(uint256 => Rooster) private tokenIdToRoosterStats;
    mapping(uint256 => Hen) private tokenIdToHenStats;
    mapping(uint256 => Bones) private tokenIdToBonesStats;
    mapping(uint256 => Zombie) private tokenIdToZombieStats;

    mapping(uint256 => uint256) public tokenIdToHenHouseId; // 0 - entity is not staked
    mapping(uint256 => HenHouse) public henHouses;
    mapping(address => uint256) private stakeCounter; // number of active hen houses

    event HenHouseEggs(
        uint256[] newEggsFromHenHouse
    );

    constructor() ERC1155("ipfs://") {
        chickenCounter = 1; // zero index is empty
        henHouseCounter = 1;
    }

    /**
     * @dev Set settings for the contract
     * @dev zero values don't change anything
     * @return current settings
     */
    function setSettings(uint256 _BOOST_BREED, uint256 _MAX_EGGS, uint256 _MAX_STAKES, uint256 _WIN_BOOST,
        uint256 _REZ_TIME, uint256 lifespan, uint256 peakDelay, uint256 peakRise, uint256 henHouseCycle,
        uint256 rezPrice, uint256 BURN_REWARD) public onlyOwner returns (Settings memory){

        if (_BOOST_BREED != 0 && settings._BOOST_BREED != _BOOST_BREED)
            {settings._BOOST_BREED = _BOOST_BREED;}
        if (_MAX_EGGS != 0 && settings._MAX_EGGS != _MAX_EGGS)
            {settings._MAX_EGGS = _MAX_EGGS;}
        if (_MAX_STAKES != 0 && settings._MAX_STAKES != _MAX_STAKES)
            {settings._MAX_STAKES = _MAX_STAKES;}
        if (_WIN_BOOST != 0 && settings._WIN_BOOST != _WIN_BOOST)
            {settings._WIN_BOOST = _WIN_BOOST;}
        if (_REZ_TIME != 0 && settings._REZ_TIME != _REZ_TIME)
            {settings._REZ_TIME = _REZ_TIME;}
        if (lifespan != 0 && settings.lifespan != lifespan)
            {settings.lifespan = lifespan;}
        if (peakDelay != 0 && settings.peakDelay != peakDelay)
            {settings.peakDelay = peakDelay;}
        if (peakRise != 0 && settings.peakRise != peakRise)
            {settings.peakRise = peakRise;}
        if (henHouseCycle != 0 && settings.henHouseCycle != henHouseCycle)
            { settings.henHouseCycle = henHouseCycle;}
        if (rezPrice != 0 && settings.rezPrice != rezPrice)
            { settings.rezPrice = rezPrice;}
        if (BURN_REWARD != 0 && settings.BURN_REWARD != BURN_REWARD)
            {settings.BURN_REWARD = BURN_REWARD;}
        return settings;
    }

    // DEV Only!
    function getUserNfts(address userAddress) public view returns (uint256[] memory) {

        return userOwnedIds[userAddress];
        
    }

    function getUserNftsWithParams(address userAddress) public view returns (uint256[][] memory) {

        uint256[] memory userNfts = getUserNfts(userAddress);
        uint256 numberOfNfts = userNfts.length;
        uint[7] memory stats;
        uint[][] memory output_array = new uint[][](numberOfNfts);

        for (uint i=0; i < numberOfNfts; i++) {
            uint[] memory temp = new uint[](10);
            temp[0] = userNfts[i];          // nft id
            temp[1] = getType(userNfts[i]); // chicken type
            stats = getStats(userNfts[i]);  // chicken stats
            for(uint j = 2; j < 9; j++){
                    temp[j]=stats[j-2]; 
                }
            temp[9] = isStaked(userNfts[i])? 1 : 0; // 1 - staked, 0 - not staked
            output_array[i] = temp;
        }

        return output_array;
    }

    function testGasForSearch(address userAddress) public returns (uint256[][] memory) {
        testCounter++;
        return getUserNftsWithParams(userAddress);
    }

    // DEV Only!
    function getUserHenHouses(address userAddress) public view returns (uint256[] memory) {

        uint256 userOwnedCounter;

        uint256[] memory tempArray = new uint256[](henHouseCounter+1);

        for (uint256 i=0; i<henHouseCounter+1; ++i) {
            if (henHouses[i].roosterId != 0 && _ownerOf[henHouses[i].roosterId] == userAddress) {
                tempArray[userOwnedCounter] = i;
                ++userOwnedCounter;
            }
        }
        // Static array to dynamic output array
        uint256[] memory userHenHouses = new uint256[](userOwnedCounter);
        for (uint256 i=0; i<userOwnedCounter; ++i) {
            userHenHouses[i] = tempArray[i];
        }

        return userHenHouses;
    }

    function getUserHenHousesWithParams(address userAddress) public view returns (uint256[][] memory) {

        uint256[] memory userHouses = getUserHenHouses(userAddress);
        uint256 numberOfHouses = userHouses.length;
        uint[][] memory output_array = new uint[][](numberOfHouses);

        for (uint i=0; i < numberOfHouses; i++) {
            
            uint[] memory temp = new uint[](5);
            temp[0] = userHouses[i];                         // henHouse id
            temp[1] = henHouses[userHouses[i]].roosterId;    // rooster id
            temp[2] = henHouses[userHouses[i]].henId;        // hen id
            temp[3] = henHouses[userHouses[i]].femaleItemId; // female item id
            temp[4] = henHouses[userHouses[i]].createTime;   // female item id

            output_array[i] = temp;
        }

        return output_array;
    }

    /**
     * @notice get max base Speed and Luck of all Roosters
     * @return max_speed max Base Speed of all Roosters
     * @return max_luck max Base Luck of all Roosters
     */
    function getMaxBaseStats() public view returns (uint256 max_speed, uint256 max_luck) {
        max_speed = maxBaseStats.maxBaseSpeed;
        max_luck = maxBaseStats.maxBaseLuck;
    }

    /**
     * @notice get corrected stat parameter for current time
     * @dev linear grow with a peak at peakDelay after birth and later decline to 1
     * @param base initial parameter
     * @param currentAge age in seconds, to avoid multiple reading of block.timestamp
     * @param speed speed of the Rooster
     * @param luck luck of the Rooster
     * @param health of the Rooster
     * @return updated_stat stat parameter corrected for current time
     */
    function currentStat(uint256 base, uint256 currentAge, uint256 speed, uint256 luck, uint256 health) 
    internal view returns (uint256 updated_stat) {
        
        uint256 _peakDelay = settings.peakDelay * (1 - 3 * speed / (4 * speed + 50));
        uint256 max_stat = base * (100 + settings.peakRise *3*luck / (4*luck + 50)) / 100;
        uint256 _lifespan = settings.lifespan * ( 33 + 300*health / (4*health + 50)) / 100;

        uint256 secondPointX = _lifespan * 3 * speed / (4 * speed + 50);
        uint256 secondPointY = max_stat * 3 * luck / (4 * luck + 50);

        if (currentAge <= _peakDelay) {

            updated_stat = (base + ((max_stat - base) * currentAge)/_peakDelay);

        } else if ((currentAge > _peakDelay) && (currentAge <= secondPointX)) {

            updated_stat = (max_stat - ((max_stat - secondPointY) *
                        (currentAge - _peakDelay))/(secondPointX - _peakDelay) );

        } else if ((currentAge > secondPointX) && (currentAge < _lifespan)) {

            updated_stat = (secondPointY - ((secondPointY - 1) *
                        (currentAge - secondPointX))/(_lifespan - secondPointX) );

        } else {
            updated_stat = 1;
        }
        
    }

    function getType(uint256 _id) public view returns (uint) {
        return uint(tokenIdToType[_id]);
    }

    /**
     * @notice get current entity stats
     * @dev stat change dynamically from birthTime through lifespan
     * @param _id id of the entity
     * @return chickenStats array uint256[6] of _id entity stats
     */
    function getStats(uint256 _id) public view returns (uint256[7] memory chickenStats) {
        uint256 currentAge;
        uint256 _henFertility;

        if(tokenIdToType[_id] == Entity.Rooster) {

            chickenStats = getCurrectRoosterStats(_id);
            
        } else if (tokenIdToType[_id] == Entity.Hen) {

            _henFertility = tokenIdToHenStats[_id].fertility;
            currentAge = block.timestamp - tokenIdToHenStats[_id].birthTime;
            chickenStats[0] = currentStat(_henFertility, 
            currentAge,
            _henFertility, 
            _henFertility,
            _henFertility);
            chickenStats[6] = tokenIdToHenStats[_id].birthTime;

        } else if (tokenIdToType[_id] == Entity.Bones) { 
            chickenStats[0] = tokenIdToBonesStats[_id].quality;
            chickenStats[6] = tokenIdToBonesStats[_id].deathTime;
        } else {
            chickenStats[0] = 0;
        }
    }

    function getCurrectRoosterStats(uint256 _id) internal view returns (uint256[7] memory currentRoosterStats) {
        Rooster memory currentRooster = tokenIdToRoosterStats[_id];
        uint256 currentAge = block.timestamp - currentRooster.birthTime;
        uint256 koeff;

        currentRoosterStats[0] = currentStat(currentRooster.attack, 
                                                currentAge,
                                                currentRooster.speed,
                                                currentRooster.luck,
                                                currentRooster.health);
        koeff = ( 1000 * currentRoosterStats[0] ) / currentRooster.attack;
        currentRoosterStats[1] = (koeff * currentRooster.defence + 500) / 1000;
        currentRoosterStats[2] = (koeff * currentRooster.health + 500) / 1000;
        currentRoosterStats[3] = (koeff * currentRooster.speed + 500) / 1000;
        currentRoosterStats[4] = (koeff * currentRooster.luck + 500) / 1000;
        currentRoosterStats[5] = currentRooster.winsCounter;
        currentRoosterStats[6] = currentRooster.birthTime;
    }


    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }


    /**
     * @notice returns address of the NFT owner
     * @param _id NFT id
     */
    function ownerOf(uint256 _id) public view returns (address) {
        return _ownerOf[_id];
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    // DEVELOPMENT ONLY!
    function mintRooster(uint256[6] memory _roosterStats, address account) public onlyOwner returns (uint256) {
        tokenIdToType[chickenCounter] = Entity.Rooster;
        // attack, defence, health, speed, luck, winsCounter, birthtime
        tokenIdToRoosterStats[chickenCounter] = (Rooster(
            _roosterStats[0],
            _roosterStats[1],
            _roosterStats[2],
            _roosterStats[3],
            _roosterStats[4],
            _roosterStats[5],
            block.timestamp));
        _mint(account, chickenCounter, 1, "");

        if(tokenIdToRoosterStats[chickenCounter].speed > maxBaseStats.maxBaseSpeed) {
            maxBaseStats.maxBaseSpeed = tokenIdToRoosterStats[chickenCounter].speed;
        }
        if(tokenIdToRoosterStats[chickenCounter].luck > maxBaseStats.maxBaseLuck) {
            maxBaseStats.maxBaseLuck = tokenIdToRoosterStats[chickenCounter].luck;
        }

        chickenCounter += 1;

        return chickenCounter - 1;
    }

    function mintMirror(uint256[5] memory _roosterStats) external onlyBattleContract returns (uint256) {
        tokenIdToType[chickenCounter] = Entity.Rooster;
        // attack, defence, health, speed, luck, winsCounter, birthtime
        tokenIdToRoosterStats[chickenCounter] = (Rooster(
            _roosterStats[0],
            _roosterStats[1],
            _roosterStats[2],
            _roosterStats[3],
            _roosterStats[4],
            0,
            block.timestamp));
        _mint(address(1), chickenCounter, 1, "");

        chickenCounter += 1;

        return chickenCounter - 1;
    }

    /**
     * @notice Create Rooster from the egg that is hatched in Egg_NFT contract
     * @param account address of the egg owner
     * @param eggQuality egg quality that is hatched
     * @return chickenId
     */
    function hatchRooster(address account, uint256 eggQuality)
        external
        onlyEggContract returns (uint256)
    {
        allAddresses.randomizerContractAddress = IAddressManager(addressManagerAddress).getAddress("randomizerContractAddress");
        tokenIdToType[chickenCounter] = Entity.Rooster;
        uint256 _eggMin = (eggQuality * 10 + 10) / 20; // round number UP
        // attack, defence, health, speed, luck, winsCounter, birthtime
        tokenIdToRoosterStats[chickenCounter] = (Rooster(
            IRandomizer(allAddresses.randomizerContractAddress).getRandomInRange(_eggMin, eggQuality, chickenCounter), 
            IRandomizer(allAddresses.randomizerContractAddress).getRandomInRange(_eggMin, eggQuality, chickenCounter + 1), 
            IRandomizer(allAddresses.randomizerContractAddress).getRandomInRange(_eggMin, eggQuality, chickenCounter + 2), 
            IRandomizer(allAddresses.randomizerContractAddress).getRandomInRange(_eggMin, eggQuality, chickenCounter + 3),
            IRandomizer(allAddresses.randomizerContractAddress).getRandomInRange(_eggMin, eggQuality, chickenCounter + 4),
            0, 
            block.timestamp));
        _mint(account, chickenCounter, 1, "");

        if(tokenIdToRoosterStats[chickenCounter].speed > maxBaseStats.maxBaseSpeed) {
            maxBaseStats.maxBaseSpeed = tokenIdToRoosterStats[chickenCounter].speed;
        }
        if(tokenIdToRoosterStats[chickenCounter].luck > maxBaseStats.maxBaseLuck) {
            maxBaseStats.maxBaseLuck = tokenIdToRoosterStats[chickenCounter].luck;
        }

        chickenCounter += 1;

        return chickenCounter - 1;
    }

    /**
     * @notice Create Hen from the egg that is hatched in Egg_NFT contract
     * @param account address of the egg owner
     * @param eggQuality egg quality that is hatched
     * @return chickenId
     */
    function hatchHen(address account, uint256 eggQuality)
        external
        onlyEggContract returns (uint256)
    {
        tokenIdToType[chickenCounter] = Entity.Hen;
        // fertility, birthtime, eggCounter
        tokenIdToHenStats[chickenCounter] = (Hen(
            IRandomizer(IAddressManager(addressManagerAddress).getAddress("randomizerContractAddress")).getRandomInRange((eggQuality * 10 + 5) / 20, eggQuality, chickenCounter), 
            block.timestamp));
        _mint(account, chickenCounter, 1, "");
        chickenCounter += 1;
        
        return chickenCounter - 1;
    }

    /**
     * @notice Create Hen from the egg that is hatched in Egg_NFT contract
     * @param _roosterId rooster id
     * @return bones quality
     */
    function roosterToBones(uint256 _roosterId) external onlyBattleContract returns (uint256) {
        
        // // Turn to Bones
        // tokenIdToType[_roosterId] = Entity.Bones;
        // tokenIdToBonesStats[_roosterId] = Bones(tokenIdToRoosterStats[_roosterId].winsCounter * 10 + 1, block.timestamp);
        // return tokenIdToBonesStats[_roosterId].quality;

        // Unstake
        tokenIdToHenHouseId[_roosterId] = 0;

        // BURN Loser
        _burnChicken(_roosterId);

        return uint256(0);

    }

    function ressurectFromBones(uint256 _bonesId) public returns (bool) {
        bool paymentDone;

        require(tokenIdToType[_bonesId] == Entity.Bones, "Only bones!");

        require(tokenIdToBonesStats[_bonesId].deathTime + settings._REZ_TIME >= block.timestamp, "Too late!");

        paymentDone = IRHC_Vault(IAddressManager(addressManagerAddress).getAddress("vaultContractAddress")).makePayment(msg.sender, settings.rezPrice);
        require(paymentDone, "Payment Error!");

        tokenIdToType[_bonesId] = Entity.Rooster;

        return true;
    }

    /**
     * @notice Stake a rooster and a hen 
     * @dev staker gets 1 egg for each hen every period of henHouseCyles seconds, _MAX_EGGS periods
     * @param _roosterId rooster id
     * @param _henId hen id
     * @param _femaleItemId optional female item id for bonus egg quality, 0 - no item
     * @return henHouseId id of new hen house
     */
    function stakeHenHouse(uint256 _roosterId, uint256 _henId, uint256 _femaleItemId) public  
    returns(uint256) {
        allAddresses.itemContractAddress = IAddressManager(addressManagerAddress).getAddress("itemContractAddress");
        // Check if none is already staked!
        // Check if all belong to msg.sender!
        require(_ownerOf[_roosterId] == msg.sender, "Rooster doesn't belong to sender!");
        require(tokenIdToHenHouseId[_roosterId] == 0, "Rooster is staked already!");
        require(_ownerOf[_henId] == msg.sender, "Hen doesn't belong to sender!");
        require(tokenIdToHenHouseId[_henId] == 0, "Hen is staked already!");
        if (_femaleItemId > 0) {
            require(IItem_NFT(allAddresses.itemContractAddress).ownerOf(_femaleItemId) == msg.sender, "Item doesn't belong to sender!");
            require(IItem_NFT(allAddresses.itemContractAddress).isStaked(_femaleItemId) == false, "Item is staked already!");
            require(IItem_NFT(allAddresses.itemContractAddress).getStats(_femaleItemId)[0] == 3, "Not a female item!");
            // Block item in Item_NFT
            IItem_NFT(allAddresses.itemContractAddress).setStaked(_femaleItemId, true);
        }

        //raise stake counter
        stakeCounter[msg.sender] += 1;
        require(stakeCounter[msg.sender] <= settings._MAX_STAKES, "User already has maximum stakes!");

        // Create hen house
        henHouses[henHouseCounter] = HenHouse(_roosterId, _henId, _femaleItemId, block.timestamp);

        tokenIdToHenHouseId[_roosterId] = henHouseCounter;
        tokenIdToHenHouseId[_henId] = henHouseCounter;

        henHouseCounter += 1;

        return henHouseCounter - 1;
    }

    /**
     * @notice Get number of cycles passed for the staking
     * @param _henHouseId hen house id
     * @return cyclesPassed quantity of cycles passed, not more than _MAX_EGGS
     */
    function checkStakeCycle(uint256 _henHouseId) public view returns (uint256) {
        uint256 cyclesPassed = (block.timestamp - henHouses[_henHouseId].createTime) / settings.henHouseCycle;
        if (cyclesPassed > 3) {cyclesPassed = settings._MAX_EGGS;}
        return cyclesPassed;
    }

    /**
     * @notice Update Hen House and generate eggs as many as cycles passed
     * @param _henHouseId hen house id
     * @return newEggs array ids of new eggs
     */
    function updateHenHouse(uint256 _henHouseId) public 
    returns (uint256[] memory) {
        require(henHouses[_henHouseId].roosterId != 0, "Hen House is empty!");
        uint256 cyclesPassed = checkStakeCycle(_henHouseId);
        require(cyclesPassed >= 1, "Hen House did not complete a cycle!");

        uint256[] memory newEggs = new uint256[](cyclesPassed);

        // reseting stake timer
        henHouses[_henHouseId].createTime = block.timestamp;

        // laying eggs
        for (uint256 i = 0; i < cyclesPassed; i++) {
            newEggs[i] = breedEgg(henHouses[_henHouseId].roosterId, 
                                    henHouses[_henHouseId].henId, 
                                    henHouses[_henHouseId].femaleItemId);
        }

        emit HenHouseEggs(newEggs);

        return newEggs;
    }

    /**
     * @notice Open staked hen house and generate eggs as many as cycles passed
     * @dev 1 rooster and 1 hen, generate 1 egg every cycle, _MAX_EGGS is a limit of useful cycles 
     * @param _henHouseId hen house id
     * @return newEggs array ids of new eggs
     */
    function releaseHenHouse(uint256 _henHouseId) public 
    returns (uint256[] memory) {
        require(henHouses[_henHouseId].roosterId != 0, "Hen House is empty!");
        require(_ownerOf[henHouses[_henHouseId].roosterId] == msg.sender, "Hen House doesn't belong to sender!");

        // generating eggs
        uint256 cyclesPassed = checkStakeCycle(_henHouseId);
        uint256[] memory newEggs = new uint256[](cyclesPassed);
        if(cyclesPassed >=1 ){
            newEggs = updateHenHouse(_henHouseId);
        }
        // releasing locks
        tokenIdToHenHouseId[henHouses[_henHouseId].roosterId] = 0;
        tokenIdToHenHouseId[henHouses[_henHouseId].henId] = 0;
        if(henHouses[_henHouseId].femaleItemId != 0) {
            IItem_NFT(IAddressManager(addressManagerAddress).getAddress("itemContractAddress")).setStaked(henHouses[_henHouseId].femaleItemId, false);
        }

        // clear Hen House
        delete henHouses[_henHouseId];

        //lower stake counter
        stakeCounter[msg.sender] -= 1;

        return newEggs;
    }

    /**
     * @notice Mint egg in Egg_NFT contract
     * @dev _BOOST_BREED is used for egg stats
     * @param _roosterId hen house rooster id
     * @param _henId hen house hen id
     * @return eggId id of the new egg
     */
    function breedEgg(uint256 _roosterId, uint256 _henId, uint256 _femaleItemId) internal returns (uint256 eggId) {

        // current logic for combo stats:
        // take average of 5 stats of the rooster
        // update this average to current time
        // take average of it and hen updated fertility
        // round number UP
        // TO DO: special use for Luck 
        uint256 comboStats;
        uint256 itemBonus;

        Rooster memory stakedRooster;
        stakedRooster = tokenIdToRoosterStats[_roosterId];
        comboStats = (currentStat(
            (stakedRooster.attack +
            stakedRooster.defence +
            stakedRooster.health +
            stakedRooster.speed +
            stakedRooster.luck) / 5, 
            block.timestamp - stakedRooster.birthTime,
            stakedRooster.speed,
            stakedRooster.luck,
            stakedRooster.health) +
            getStats(_henId)[0]) / 2 ;

        if (_femaleItemId > 0) {
            itemBonus = IItem_NFT(IAddressManager(addressManagerAddress).getAddress("itemContractAddress")).getStats(_femaleItemId)[2];
        }
        eggId = IEgg_NFT(IAddressManager(addressManagerAddress).getAddress("eggContractAddress")).layEgg(_ownerOf[_henId],
                            (settings._BOOST_BREED * comboStats) / 100,
                            stakedRooster.winsCounter * settings._WIN_BOOST + itemBonus);

    }
    
    /**
     * @notice Get stake status of rooster or hen
     * @param _id id of the chicken
     * @return bool is chicken staked in a hen house already or not
     */
    function isStaked(uint256 _id) public view returns (bool) {
        return tokenIdToHenHouseId[_id] == 0 ? false : true;
    }

    /**
     * @notice Set stake status
     * @dev may only be set externally by NFT_Rooster_Battle
     * @param _id id of the item
     * @param _status status true for staked, false for not staked
     */
    function setStaked(uint256 _id, bool _status) external onlyBattleContract {
        if (_status) {
            tokenIdToHenHouseId[_id] = 1;
        } else {
            tokenIdToHenHouseId[_id] = 0;
        }

    }

    /**
     * @notice Increment wins counter by 1
     * @dev may only be set externally by NFT_Rooster_Battle
     * @param _id id of the item
     */
    function plusOneWinsCounter(uint256 _id) external onlyBattleContract {
        
        tokenIdToRoosterStats[_id].winsCounter += 1;

    }

    function craftSacrifice(uint256 _chickenId) external onlyCraftContract {
        _burnChicken(_chickenId);
    }

    function burn(uint256 _chickenId) public {
        require(msg.sender == ownerOf(_chickenId), "Only owner!");
        _burnChicken(_chickenId);
        IRHC_Vault(IAddressManager(addressManagerAddress).getAddress("vaultContractAddress")).rewardAccount(msg.sender, settings.BURN_REWARD);
    }

    function _burnChicken(uint256 _chickenId) internal {

        address account = ownerOf(_chickenId);
        _burn(account, _chickenId, 1);
        delete tokenIdToType[_chickenId];
        delete tokenIdToRoosterStats[_chickenId];
        delete tokenIdToHenStats[_chickenId];
        delete tokenIdToBonesStats[_chickenId];
        delete tokenIdToZombieStats[_chickenId];
        delete _ownerOf[_chickenId];
    }

    function burnMany(uint256[] memory _ids) public {
        for (uint256 i = 0; i < _ids.length; i++) {
            burn(_ids[i]);
        }
    }

    function _removeFromOwnedIds(address userAddress, uint256 _id) internal {
        // clearing the array
        uint i = 0;
        while (userOwnedIds[userAddress][i] != _id) {
            i++;
        }
        // Move the last element into the place to delete
        userOwnedIds[userAddress][i] = userOwnedIds[userAddress][userOwnedIds[userAddress].length - 1];
        // Remove the last element
        userOwnedIds[userAddress].pop();
    }

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        whenNotPaused
        override(ERC1155) // ERC1155Supply removed
    {   
        // transferring ownership
        for (uint256 i = 0; i < ids.length; i++) {
            // staked ids may not be transferred
            require(tokenIdToHenHouseId[ids[i]] == 0, "Chicken is Staked!");
            if (from != address(0)){
                _removeFromOwnedIds(from, ids[i]);
            }
            if (to != address(0)){
                userOwnedIds[to].push(ids[i]);
                _ownerOf[ids[i]] = to;
            }
        }
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

}
