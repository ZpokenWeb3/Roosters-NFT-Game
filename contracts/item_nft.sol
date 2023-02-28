// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import "utils/inter.sol";
import "interfaces/iegg_nft.sol";
import "interfaces/ivault.sol";
import "interfaces/irandomizer.sol";

contract Item_NFT is ERC1155, Interconnected, Pausable {

    uint256 internal itemCounter;
    uint256 internal testCounter;

    enum ItemType {Weapon, Armor, Artefact, FemaleItem, ZombieItem}

    struct Settings {
        uint256 WEAPON_ARMOR_BONUS; // absolute value, every item has unique bonus from egg quality
        uint256 MALE_ZOMBIE_ITEMS; // percentage
        uint256 SPELL_ITEM_CEILING; // max ceiling of spell items boost/ward, 20 base + bonus from egg quality
        uint256 FEMALE_ITEMS_BONUS; // absolute value, every item has unique bonus from egg quality
        uint256 BURN_REWARD;
        uint256 SPRIG_PRICE;
        uint256 ANKH_PRICE;
    }

    Settings settings = Settings({
        WEAPON_ARMOR_BONUS: 100,
        MALE_ZOMBIE_ITEMS: 1000,
        SPELL_ITEM_CEILING: 50,
        FEMALE_ITEMS_BONUS: 100,
        BURN_REWARD: 0.5 ether,
        SPRIG_PRICE: 10 ether,
        ANKH_PRICE: 50 ether
    });

    struct Item {
        ItemType itemType;
        uint256 selector;
        uint256 bonus;
        uint256 zodiac;
        uint256 requiredWins;
        bool vampiric;
    }

    struct AllParams {
            uint8[10] weaponSelectors;
            uint8[10] weaponBaseParameters;
            uint8[10] weaponWins;
            uint8[10] armorSelectors;
            uint8[10] armorBaseParameters;
            uint8[10] armorWins;
            uint8[21] maleItemSelectors;
            uint8[21] maleItemBaseParameters;
            uint8[21] maleItemWins;
            uint8[5] femaleItemSelectors;
            uint8[5] femaleItemBaseParameters;
            uint8[5] zombieItemSelectors;
            uint8[5] zombieItemBaseParameters;
    }

    mapping(uint256 => address) private _ownerOf;
    mapping(address => uint256[]) private userOwnedIds;
    mapping(uint256 => Item) private tokenIdToStats;
    mapping(uint256 => bool) private _isStaked;

    AllParams private data;


    constructor() ERC1155("ipfs://") {
        itemCounter = 1; // 0 is an empty item

        data.weaponSelectors = [0,20,38,54,67,77,85,91,96,100];
        data.weaponBaseParameters = [0,2,5,10,15,20,30,40,50,60];
        data.weaponWins = [0,0,0,1,2,3,5,10,15,20];

        data.armorSelectors = data.weaponSelectors;
        data.armorBaseParameters = data.weaponBaseParameters;
        data.armorWins = data.weaponWins;

        data.maleItemSelectors = [0,4,11,18,27,32,34,43,48,50,59,64,66,67,76,81,83,92,97,99,100];
        data.maleItemBaseParameters = [0,0,20,20,25,50,75,25,50,75,25,33,50,100,25,33,50,25,33,50,20];
        data.maleItemWins = [0,0,3,3,0,3,5,0,3,5,0,1,5,10,0,3,5,0,3,4,0];

        data.femaleItemSelectors = [0,40,70,90,100];
        data.femaleItemBaseParameters = [0,10,20,30,40];

        data.zombieItemSelectors = [0, 25, 50, 75, 100];
        data.zombieItemBaseParameters =[0, 5, 5, 5, 5];
    }

    /**
     * @dev Set settings for the contract
     * @dev zero values don't change anything
     * @return current settings
     */
    function setSettings(uint256 WEAPON_ARMOR_BONUS, uint256 MALE_ZOMBIE_ITEMS, uint256 SPELL_ITEM_CEILING,
        uint256 FEMALE_ITEMS_BONUS, uint256 BURN_REWARD, uint256 SPRIG_PRICE, uint256 ANKH_PRICE) public onlyOwner returns (Settings memory){

        if (WEAPON_ARMOR_BONUS != 0 && settings.WEAPON_ARMOR_BONUS != WEAPON_ARMOR_BONUS)
            {settings.WEAPON_ARMOR_BONUS = WEAPON_ARMOR_BONUS;}
        if (MALE_ZOMBIE_ITEMS != 0 && settings.MALE_ZOMBIE_ITEMS != MALE_ZOMBIE_ITEMS)
            {settings.MALE_ZOMBIE_ITEMS = MALE_ZOMBIE_ITEMS;}
        if (SPELL_ITEM_CEILING != 0 && settings.SPELL_ITEM_CEILING != SPELL_ITEM_CEILING)
            {settings.SPELL_ITEM_CEILING = SPELL_ITEM_CEILING;}
        if (FEMALE_ITEMS_BONUS != 0 && settings.FEMALE_ITEMS_BONUS != FEMALE_ITEMS_BONUS)
            {settings.FEMALE_ITEMS_BONUS = FEMALE_ITEMS_BONUS;}
        if (BURN_REWARD != 0 && settings.BURN_REWARD != BURN_REWARD)
            {settings.BURN_REWARD = BURN_REWARD;}
        if (SPRIG_PRICE != 0 && settings.SPRIG_PRICE != SPRIG_PRICE)
            {settings.SPRIG_PRICE = SPRIG_PRICE;}
        if (ANKH_PRICE != 0 && settings.ANKH_PRICE != ANKH_PRICE)
            {settings.ANKH_PRICE = ANKH_PRICE;}    

        return settings;
    }

    // DEV Only!
    function getUserNfts(address userAddress) public view returns (uint256[] memory) {
        return userOwnedIds[userAddress];
    }

    function getUserNftsWithParams(address userAddress) public view returns (uint256[][] memory) {

        uint256[] memory userNfts = getUserNfts(userAddress);
        uint256 numberOfNfts = userNfts.length;
        uint[6] memory stats;
        uint[][] memory output_array = new uint[][](numberOfNfts);

        for (uint i=0; i < numberOfNfts; ++i) {
            uint[] memory temp = new uint[](8);
            stats = getStats(userNfts[i]);  // item stats
            temp[0] = userNfts[i];          // item id
            temp[1] = stats[0];
            temp[2] = stats[1];
            temp[3] = stats[2];
            temp[4] = stats[3];
            temp[5] = stats[4];
            temp[6] = stats[5];
            temp[7] = isStaked(userNfts[i])? 1 : 0; // 1 - staked, 0 - not staked

            output_array[i] = temp;
        }

        return output_array;
    }

    function testGasForSearch(address userAddress) public returns (uint256[][] memory) {
        testCounter++;
        return getUserNftsWithParams(userAddress);
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

    function getBonusAndWins(ItemType itemType, uint256 selector, uint256 eggQuality) internal view returns (uint256, uint256) {
        uint256 bonus;
        uint256 requiredWins;


        if (itemType == ItemType.Weapon) {
            for(uint8 i=0;i<data.weaponSelectors.length;i++) {
                if (selector<=data.weaponSelectors[i]) {
                    bonus = data.weaponBaseParameters[i] * (settings.WEAPON_ARMOR_BONUS + eggQuality) / settings.WEAPON_ARMOR_BONUS;
                    requiredWins = data.weaponWins[i];
                    break;
                }
            }
        }

        if (itemType == ItemType.Armor) {
            for(uint8 i=0;i<data.armorSelectors.length;i++) {
                if (selector<=data.armorSelectors[i]) {
                    bonus = data.armorBaseParameters[i] * (settings.WEAPON_ARMOR_BONUS + eggQuality) / settings.WEAPON_ARMOR_BONUS;
                    requiredWins = data.armorWins[i];
                    break;
                }
            }
            
        }

        if (itemType == ItemType.Artefact) {
            for(uint8 i=0;i<data.maleItemSelectors.length;i++) {
                if (selector<=data.maleItemSelectors[i]) {
                    bonus = data.maleItemBaseParameters[i] * (settings.MALE_ZOMBIE_ITEMS + eggQuality) / settings.MALE_ZOMBIE_ITEMS;
                    requiredWins = data.maleItemWins[i];
                    // Spell items
                    if (selector>4 && selector<=18) {
                        bonus = data.maleItemBaseParameters[i] + 
                        30 * eggQuality / (settings.SPELL_ITEM_CEILING + eggQuality);
                    }
                    // Mint Sprig
                    if (selector == 100) {
                        bonus = data.maleItemBaseParameters[i] + 
                        30 * eggQuality / (settings.SPELL_ITEM_CEILING + eggQuality);
                    }
                    break;
                }
            }
        }

        if (itemType == ItemType.FemaleItem) {
            for(uint8 i=0;i<data.femaleItemSelectors.length;i++) {
                if (selector<=data.femaleItemSelectors[i]) {
                    bonus = data.femaleItemBaseParameters[i] * (settings.FEMALE_ITEMS_BONUS + eggQuality) / settings.FEMALE_ITEMS_BONUS;
                    requiredWins = 0;
                    break;
                }
            }
        }

        if (itemType == ItemType.ZombieItem) {
            for(uint8 i = 0; i < data.zombieItemSelectors.length; i++){
                if (selector<=data.zombieItemSelectors[i]){
                    bonus = data.armorBaseParameters[i] * (settings.MALE_ZOMBIE_ITEMS + eggQuality) / settings.MALE_ZOMBIE_ITEMS;
                    requiredWins = 0;
                    break;
                }
            }
        }
        return (bonus, requiredWins);
    }

    /**
     * @notice get item stats
     * @dev selector defines the specific item and base parameter, bonus includes extra from egg quality
     * @param _id id of the item
     * @return itemStats array uint256[6]
     */
    function getStats(uint256 _id) public view returns (uint256[6] memory itemStats) {

        itemStats[0] = uint256(tokenIdToStats[_id].itemType);
        itemStats[1] = tokenIdToStats[_id].selector;
        itemStats[2] = tokenIdToStats[_id].bonus;
        itemStats[3] = tokenIdToStats[_id].zodiac;
        itemStats[4] = tokenIdToStats[_id].requiredWins;
        itemStats[5] = tokenIdToStats[_id].vampiric == true ? 1: 0;
    }

    /**
     * @notice Create Item from the egg that is hatched in Egg_NFT contract
     * @dev actual item is defined by random selector in the range 1-100
     * @param account address of the egg owner
     * @param eggQuality egg quality that is hatched, eggQuality to stats
     * @return itemId
     */
    function hatchItem(address account, uint256 eggQuality)
        external onlyEggContract returns (uint256)
    {
        return _createNewItem(account, eggQuality, IRandomizer(IAddressManager(addressManagerAddress).getAddress("randomizerContractAddress")).getRandomInRange(0,3,itemCounter+1));
    }

    function _createNewItem(address account, uint256 eggQuality, uint256 itemType) internal returns (uint256){
        ItemType _type;
        uint256 _selector;
        uint256 _bonus;
        uint256 _zodiac;
        uint256 _requiredWins;
        bool _vampiric;

        // weapon, armor, artefact, female item
        _type = ItemType(itemType);
        // random number in the range 1-100
        // determines the probability of an item
        _selector = IRandomizer(IAddressManager(addressManagerAddress).getAddress("randomizerContractAddress")).getRandomInRange(1, 100, itemCounter+2);
        // 20% vampiric
        if (_type == ItemType.Weapon && _type == ItemType.Armor) {
            _vampiric = (IRandomizer(IAddressManager(addressManagerAddress).getAddress("randomizerContractAddress")).getRandomInRange(1, 10, itemCounter+3) >= 9);
        }

        (_bonus, _requiredWins) = getBonusAndWins(_type, _selector, eggQuality);

        _zodiac = IRandomizer(IAddressManager(addressManagerAddress).getAddress("randomizerContractAddress")).getRandomInRange(0, 6, itemCounter+4);

        tokenIdToStats[itemCounter] = Item(
            _type,
            _selector,
            _bonus,
            _zodiac,
            _requiredWins,
            _vampiric);

        _mint(account, itemCounter, 1, "");
        itemCounter += 1;
        
        return (itemCounter - 1);
    }

    function craftNewItem(address account, uint256 _quality, uint256 _itemType)
        external onlyCraftContract returns (uint256)
    {
        return _createNewItem(account, _quality, _itemType);
    }

    function buyMintSprigs(uint256 quantity) public returns (uint256[] memory)
    {
        uint256[] memory newSprigs = new uint256[](quantity);
        bool paymentDone;

        paymentDone = IRHC_Vault(IAddressManager(addressManagerAddress).getAddress("vaultContractAddress")).makePayment(msg.sender, settings.SPRIG_PRICE * quantity);
        require(paymentDone, "Payment Error!");

        for (uint256 i = 0; i < quantity; i++) {
            // Minting Mint Sprig Item
            tokenIdToStats[itemCounter] = Item(ItemType.Artefact,100,40,0,0,false);

            _mint(msg.sender, itemCounter, 1, "");
            newSprigs[i] = itemCounter;
            itemCounter += 1;
        }
        return newSprigs;
    }

    function buyAnkhs(uint256 quantity) public returns (uint256[] memory)
    {
        uint256[] memory newAnkhs = new uint256[](quantity);
        bool paymentDone;

        paymentDone = IRHC_Vault(IAddressManager(addressManagerAddress).getAddress("vaultContractAddress")).makePayment(msg.sender, settings.ANKH_PRICE * quantity);
        require(paymentDone, "Payment Error!");

        for (uint256 i = 0; i < quantity; i++) {
            // Minting Ankh of Resurrection Item
            tokenIdToStats[itemCounter] = Item(ItemType.Artefact,4,40,0,0,false);

            _mint(msg.sender, itemCounter, 1, "");
            newAnkhs[i] = itemCounter;
            itemCounter += 1;
        }
        return newAnkhs;
    }

    // DEVELOPMENT ONLY!
    function mintItem(uint256 _type, uint256 _selector, uint256 _eggQuality, 
                      uint256 _zodiac, uint256 _requiredWins, bool _vampiric,
                      address account) public onlyOwner returns (uint256) {

        uint256 _bonus;

        (_bonus, ) = getBonusAndWins(ItemType(_type), _selector, _eggQuality);
                          
        tokenIdToStats[itemCounter] = Item(
            ItemType(_type),
            _selector,
            _bonus,
            _zodiac,
            _requiredWins,
            _vampiric);

        _mint(account, itemCounter, 1, "");
        itemCounter += 1;
        
        return (itemCounter - 1);
    }

    /**
     * @notice Set stake status of an item
     * @dev may only be set by Chicken_NFT or NFT_Rooster_Battle
     * @param _id id of the item
     * @param _status status true for staked, false for not staked
     */
    function setStaked(uint256 _id, bool _status) external onlyChickenOrBattleContracts {
        _isStaked[_id] = _status;
    }

    /**
     * @notice Get stake status of female item
     * @param _id id of the female item
     * @return bool staked already or not
     */
    function isStaked(uint256 _id) public view returns (bool) {
        return _isStaked[_id];
    }

    function burnItemNft(uint256 _itemId) external onlyChickenOrBattleContracts {
        _burnItem(_itemId);
    }

    /*
    struct Item {
        ItemType itemType;
        uint256 selector;
        uint256 bonus;
        uint256 zodiac;
        uint256 requiredWins;
        bool vampiric;
    }
    */
    function craftWithSprig(uint256 updatedItemId, bool levelUp, uint256 mintSprigQuality, uint256 burnItemId) external onlyCraftContract {
        Item memory updatedItem;
        uint256 baseBonus;
        uint256 newBaseBonus;
        

        updatedItem.itemType = tokenIdToStats[updatedItemId].itemType;
        updatedItem.selector = tokenIdToStats[updatedItemId].selector;
        (baseBonus, ) = getBonusAndWins(updatedItem.itemType, tokenIdToStats[updatedItemId].selector, 0);
        if (levelUp) {
            if (updatedItem.itemType == ItemType.Weapon || updatedItem.itemType == ItemType.Armor){
                for (uint256 i; i < data.weaponSelectors.length - 1; i++) {
                    if (updatedItem.selector <= data.weaponSelectors[i]) {
                        updatedItem.selector = data.weaponSelectors[i+1];
                        break;
                    }
                }
            }
            if (updatedItem.itemType == ItemType.Artefact){
                for (uint256 i; i < data.maleItemSelectors.length - 1; i++) {
                    if (updatedItem.selector <= data.maleItemSelectors[i]) {
                        updatedItem.selector = data.maleItemSelectors[i+1];
                        break;
                    }
                }
            }
            if (updatedItem.itemType == ItemType.FemaleItem){
                for (uint256 i; i < data.femaleItemSelectors.length - 1; i++) {
                    if (updatedItem.selector <= data.femaleItemSelectors[i]) {
                        updatedItem.selector = data.femaleItemSelectors[i+1];
                        break;
                    }
                }
            }
            if (updatedItem.itemType == ItemType.ZombieItem){
                for (uint256 i; i < data.zombieItemSelectors.length - 1; i++) {
                    if (updatedItem.selector <= data.zombieItemSelectors[i]) {
                        updatedItem.selector = data.zombieItemSelectors[i+1];
                        break;
                    }
                }
            }
            
            (newBaseBonus, updatedItem.requiredWins) = getBonusAndWins(updatedItem.itemType, updatedItem.selector, 0);
            updatedItem.bonus = newBaseBonus + (tokenIdToStats[updatedItemId].bonus - baseBonus);

        } else {

            updatedItem.requiredWins = tokenIdToStats[updatedItemId].requiredWins;
            updatedItem.bonus = baseBonus + 1 + (tokenIdToStats[updatedItemId].bonus - baseBonus) * (100 + mintSprigQuality) / 100;

        }

        updatedItem.zodiac = tokenIdToStats[updatedItemId].zodiac;
        updatedItem.vampiric = tokenIdToStats[updatedItemId].vampiric;

        tokenIdToStats[updatedItemId] = updatedItem;
        
        _burnItem(burnItemId);
    }

    function craftMixSameType(uint256 updatedItemId, uint256 sameTypeBonus, uint256 burnItemId) external onlyCraftContract {
        Item memory updatedItem;

        updatedItem.itemType = tokenIdToStats[updatedItemId].itemType;
        updatedItem.selector = tokenIdToStats[updatedItemId].selector;

        updatedItem.bonus = tokenIdToStats[updatedItemId].bonus +
            tokenIdToStats[burnItemId].bonus * sameTypeBonus / 100 + 1;

        updatedItem.zodiac = tokenIdToStats[updatedItemId].zodiac;
        updatedItem.requiredWins = tokenIdToStats[updatedItemId].requiredWins;
        updatedItem.vampiric = tokenIdToStats[updatedItemId].vampiric;

        tokenIdToStats[updatedItemId] = updatedItem;
        
        _burnItem(burnItemId);
    }

    function craftItemLiveSacrifice(uint256 updatedItemId, uint256 addedBonus) external onlyCraftContract {
        Item memory updatedItem;

        updatedItem.itemType = tokenIdToStats[updatedItemId].itemType;
        updatedItem.selector = tokenIdToStats[updatedItemId].selector;

        updatedItem.bonus = tokenIdToStats[updatedItemId].bonus + addedBonus;

        updatedItem.zodiac = tokenIdToStats[updatedItemId].zodiac;
        updatedItem.requiredWins = tokenIdToStats[updatedItemId].requiredWins;
        updatedItem.vampiric = tokenIdToStats[updatedItemId].vampiric;

        tokenIdToStats[updatedItemId] = updatedItem;

    }

    function burn(uint256 _itemId) public {
        require(msg.sender == ownerOf(_itemId), "Only owner!");
        _burnItem(_itemId);
        IRHC_Vault(IAddressManager(addressManagerAddress).getAddress("vaultContractAddress")).rewardAccount(msg.sender, settings.BURN_REWARD);
    }

    function _burnItem(uint256 _itemId) internal {
        address account = ownerOf(_itemId);
        _burn(account, _itemId, 1);
        delete tokenIdToStats[_itemId];
        delete _ownerOf[_itemId];
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

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory _data)
        internal
        whenNotPaused
        override(ERC1155) // ERC1155Supply removed
    {   
        // transferring ownership
        for (uint256 i = 0; i < ids.length; i++) {
            // staked ids may not be transferred
            require(_isStaked[ids[i]] == false, "Item is Staked!");
            if (from != address(0)){
                _removeFromOwnedIds(from, ids[i]);
            }
            if (to != address(0)){
                userOwnedIds[to].push(ids[i]);
                _ownerOf[ids[i]] = to;
            }
        }
        super._beforeTokenTransfer(operator, from, to, ids, amounts, _data);
    }

}
