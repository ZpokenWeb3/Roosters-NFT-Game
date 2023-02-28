// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import "utils/inter.sol";
import "interfaces/iegg_nft.sol";
import "interfaces/ivault.sol";
import "interfaces/irandomizer.sol";

contract Spell_NFT is ERC1155, Interconnected, Pausable {

    uint256 internal spellCounter;
    uint256 internal testCounter;

    struct Settings {
        uint256 SLEEP_CHANCE_RANGE;
        uint256 HEAL_PERCENTAGE;
        uint256 BUFFS_DEBUFFS;
        uint256 BURN_REWARD;
    }

    Settings settings = Settings({
        SLEEP_CHANCE_RANGE: 40,
        HEAL_PERCENTAGE: 20,
        BUFFS_DEBUFFS: 13,
        BURN_REWARD: 0.5 ether
    });

    struct Spell {
        uint256 selector;
        uint256 eggQuality;
        uint256 requiredWins;
    }

    mapping(uint256 => address) private _ownerOf;
    mapping(address => uint256[]) private userOwnedIds;
    mapping(uint256 => Spell) private tokenIdToStats;
    mapping(uint256 => bool) private _isStaked;

    constructor() ERC1155("ipfs://") {
        spellCounter = 1; // 0 is an empty spell
    }

    /**
     * @dev Set settings for the contract
     * @dev zero values don't change anything
     * @return current settings
     */
    function setSettings(uint256 SLEEP_CHANCE_RANGE, uint256 HEAL_PERCENTAGE, 
                        uint256 BUFFS_DEBUFFS, uint256 BURN_REWARD) public onlyOwner
        returns (Settings memory){

        if (SLEEP_CHANCE_RANGE != 0 && settings.SLEEP_CHANCE_RANGE != SLEEP_CHANCE_RANGE)
            {settings.SLEEP_CHANCE_RANGE = SLEEP_CHANCE_RANGE;}
        if (HEAL_PERCENTAGE != 0 && settings.HEAL_PERCENTAGE != HEAL_PERCENTAGE)
            {settings.HEAL_PERCENTAGE = HEAL_PERCENTAGE;}
        if (BUFFS_DEBUFFS != 0 && settings.BUFFS_DEBUFFS != BUFFS_DEBUFFS)
            {settings.BUFFS_DEBUFFS = BUFFS_DEBUFFS;}
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
        uint[3] memory stats;
        uint[][] memory output_array = new uint[][](numberOfNfts);

        for (uint i=0; i < numberOfNfts; i++) {
            uint[] memory temp = new uint[](5);
            temp[0] = userNfts[i];          // spell id
            stats = getStats(userNfts[i]);  // spell stats
            for(uint j = 1; j < 4; j++){
                    temp[j]=stats[j-1]; 
                }
            temp[4] = isStaked(userNfts[i])? 1 : 0; // 1 - staked, 0 - not staked
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

    /**
     * @notice get spell stats
     * @dev selector defines the specific base parameter, egg quality - bonus over base value
     * @param _id id of the spell
     * @return spellStats array uint256[3]
     */
    function getStats(uint256 _id) public view returns (uint256[3] memory spellStats) {
        uint256 _selector;
        
        _selector = tokenIdToStats[_id].selector;
        spellStats[0] = _selector;
        
        // Convert selector and eggQuality to real Bonus
	    if(_selector == 0){
                spellStats[1] = 0;
        } else if(_selector <= 5){
            // sleep chance
            spellStats[1] = 30 + settings.SLEEP_CHANCE_RANGE * tokenIdToStats[_id].eggQuality / (50 + tokenIdToStats[_id].eggQuality);
            spellStats[2] = 5;
        } else if (_selector <= 20){
            // heal
            spellStats[1] = 10 + settings.HEAL_PERCENTAGE * tokenIdToStats[_id].eggQuality / (50 + tokenIdToStats[_id].eggQuality);
            spellStats[2] = 3;
        } else if (_selector <= 100){
            // all buffs and debuffs
            spellStats[1] = 2 + settings.BUFFS_DEBUFFS * tokenIdToStats[_id].eggQuality / (50 + tokenIdToStats[_id].eggQuality);
            spellStats[2] = 3;
        } 
    }

    /**
     * @notice Create Spell from the egg that is hatched in Egg_NFT contract
     * @dev actual Spell is defined by random selector in the range 1-100
     * @param account address of the egg owner
     * @param eggQuality egg quality that is hatched, eggQuality to stats
     * @return itemId
     */
    function hatchSpell(address account, uint256 eggQuality)
        external
        onlyEggContract returns (uint256)
    {
        uint256 _selector;
        uint256 _requiredWins;

        // random number in the range 1-100
        // determines the probability of an item
        _selector = IRandomizer(IAddressManager(addressManagerAddress).getAddress("randomizerContractAddress")).getRandomInRange(1, 100, spellCounter+1);
        _requiredWins = 0;

        tokenIdToStats[spellCounter] = Spell(
            _selector,
            eggQuality,
            _requiredWins);

        _mint(account, spellCounter, 1, "");
        spellCounter += 1;
        
        return (spellCounter - 1);
    }

    // DEVELOPMENT ONLY!
    function mintSpell(uint256 _selector, uint256 _eggQuality, 
                      uint256 _requiredWins,
                      address account) public onlyOwner returns (uint256) {
                          
        tokenIdToStats[spellCounter] = Spell(
            _selector,
            _eggQuality,
            _requiredWins
            );

        _mint(account, spellCounter, 1, "");
        spellCounter += 1;
        
        return (spellCounter - 1);
    }

    /**
     * @notice Set stake status of the spell
     * @dev may only be set by Chicken_NFT or NFT_Rooster_Battle
     * @param _id id of the spell
     * @param _status status true for staked, false for not staked
     */
    function setStaked(uint256 _id, bool _status) external onlyChickenOrBattleContracts {
        _isStaked[_id] = _status;
    }

    /**
     * @notice Get stake status of the spell
     * @param _id id of the spell
     * @return bool staked already or not
     */
    function isStaked(uint256 _id) public view returns (bool) {
        return _isStaked[_id];
    }

    function burn(uint256 _spell_id) public {

        require(msg.sender == ownerOf(_spell_id), "Only owner!");

        _burnSpell(_spell_id);

        IRHC_Vault(IAddressManager(addressManagerAddress).getAddress("vaultContractAddress")).rewardAccount(msg.sender, settings.BURN_REWARD);
    }

    function _burnSpell(uint256 _spell_id) internal {
        address account = ownerOf(_spell_id);
        _burn(account, _spell_id, 1);
        delete tokenIdToStats[_spell_id];
        delete _ownerOf[_spell_id];
    }

    function burnMany(uint256[] memory _ids) public {
        for (uint256 i = 0; i < _ids.length; i++) {
            burn(_ids[i]);
        }
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
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
            require(_isStaked[ids[i]] == false, "Spell is Staked!");
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