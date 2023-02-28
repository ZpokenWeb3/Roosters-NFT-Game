// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import "utils/inter.sol";
import "interfaces/ichicken_nft.sol";
import "interfaces/iitem_nft.sol";
import "interfaces/ispell_nft.sol";
import "interfaces/irandomizer.sol";
import "interfaces/ivault.sol";

contract Egg_NFT is ERC1155, Interconnected, Pausable {

    uint256 internal eggCounter;
    uint256 internal testCounter;

    struct Settings {
        uint256 _CEILING; // Basic Eggs can't be better than _CEILING
        uint256 eggPrice; // Basic egg mint price in Wei
    }

    Settings settings = Settings({
        _CEILING: 40,
        eggPrice: 1 ether
    });

    struct Egg {
        uint256 quality;
        uint256 birthTime;
    }

    mapping(uint256 => address) private _ownerOf;
    mapping(address => uint256[]) private userOwnedIds;
    mapping(uint256 => Egg) private tokenIdToEggStats;

    event EggHatched(
        address indexed owner,
        uint256 eggId,
        uint256 newType,
        uint256 newId,
        uint256 timestamp
    );

    event HatchMany(
        uint256[] newType,
        uint256[] newId
    );

    constructor() ERC1155("ipfs://") {
        eggCounter = 1; // zero index is empty
    }

    /**
     * @dev Set settings for the contract
     * @dev zero values don't change anything
     * @return current settings
     */
    function setSettings(uint256 _CEILING, uint256 eggPrice) public onlyOwner returns(Settings memory){
        if (_CEILING != 0 && settings._CEILING != _CEILING)
            {settings._CEILING = _CEILING;}
        if (eggPrice != 0 && settings.eggPrice != eggPrice)
            {settings.eggPrice = eggPrice;}
        return settings;
    }


    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    /**
     * @notice returns address of the NFT owner
     * @param _id NFT id
     * @return address of the NFT id owner
     */
    function ownerOf(uint256 _id) public view returns (address) {
        return _ownerOf[_id];
    }
    // DEV Only!
    function getUserNfts(address userAddress) public view returns (uint256[] memory) {
        return userOwnedIds[userAddress];
    }
    // DEV Only!
    function getUserNftsWithParams(address userAddress) public view returns (uint256[][] memory) {

        uint256[] memory userNfts = getUserNfts(userAddress);
        uint256 numberOfNfts = userNfts.length;
        uint[][] memory output_array = new uint[][](numberOfNfts);
        
        for (uint i=0; i < numberOfNfts; ++i) {
            uint[] memory temp = new uint[](3);
            temp[0] = userNfts[i];  // nft id
            temp[1] = tokenIdToEggStats[userNfts[i]].quality;
            temp[2] = tokenIdToEggStats[userNfts[i]].birthTime;
            output_array[i] = temp;
        }

        return output_array;
    }
    
    function testGasForSearch(address userAddress) public returns (uint256[][] memory) {
        testCounter++;
        return getUserNftsWithParams(userAddress);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function getStats(uint256 _eggId) public view returns (Egg memory eggStats) {
        eggStats = tokenIdToEggStats[_eggId];
    }

    /**
     * @notice generate basic egg with quality in the range from 1 to _CEILING
     * @dev msg.sender is used, price amount should be msg.value
     * @return eggId id of the new basic egg
     */
    function mint()
        public 
        returns (uint256)
    {
        bool paymentDone;

        paymentDone = IRHC_Vault(IAddressManager(addressManagerAddress).getAddress("vaultContractAddress")).makePayment(msg.sender, settings.eggPrice);
        require(paymentDone, "Payment Error!");

        tokenIdToEggStats[eggCounter] = Egg(IRandomizer(IAddressManager(addressManagerAddress).getAddress("randomizerContractAddress")).getRandomInRange(1, settings._CEILING,
            uint256(keccak256(abi.encodePacked(msg.sender))) + eggCounter), block.timestamp);
        
        _mint(msg.sender, eggCounter, 1, "");
        eggCounter += 1;

        return eggCounter - 1;
    }

    /**
     * @notice generate several basic eggs
     * @dev msg.sender is used, (price * quantity) amount should be msg.value
     * @param quantity how many eggs to mint
     * @return eggId[] array of ids of the new basic eggs
     */
    function mintMany(uint256 quantity)
        public 
        returns (uint256[] memory)
    {
        uint256[] memory newEggs = new uint256[](quantity);
        bool paymentDone;

        paymentDone = IRHC_Vault(IAddressManager(addressManagerAddress).getAddress("vaultContractAddress")).makePayment(msg.sender, settings.eggPrice * quantity);
        require(paymentDone, "Payment Error!");

        for (uint256 i = 0; i < quantity; i++) {

            tokenIdToEggStats[eggCounter + i] = Egg(IRandomizer(IAddressManager(addressManagerAddress).getAddress("randomizerContractAddress")).getRandomInRange(1, settings._CEILING,
                uint256(keccak256(abi.encodePacked(msg.sender))) + eggCounter + i), block.timestamp);

            _mint(msg.sender, eggCounter + i, 1, "");
            newEggs[i] = eggCounter + i;
        }
        eggCounter += quantity;

        return newEggs;
    }

    /**
     * @notice lay egg by Hen in Chicken_NFT
     * @param account user address
     * @return eggId id of the new egg
     */
    function layEgg(address account, uint256 _breedCeiling, uint256 _bonusQuality)
        external
        onlyChickenContract
        returns (uint256)
    {   
        uint256 randomNumber;
        randomNumber = IRandomizer(IAddressManager(addressManagerAddress).getAddress("randomizerContractAddress")).getRandomInRange((_breedCeiling * 10 + 30) / 40, _breedCeiling,
            uint256(keccak256(abi.encodePacked(msg.sender))) + eggCounter);
        randomNumber += _bonusQuality;

        tokenIdToEggStats[eggCounter] = Egg(randomNumber, block.timestamp );
        _mint(account, eggCounter, 1, "");
        eggCounter += 1;

        return eggCounter - 1;
    }

    /**
     * @notice Create entities in the Chicken_NFT contract from one egg
     * @dev can be called only by egg owner, can hatch while staking
     * @param _eggid unique id of the egg
     * @return newType type of the new entity
     * @return newId id of the new entity
     */
    function hatchEgg(uint256 _eggid) public returns (uint256 newType, uint256 newId) {
        require(balanceOf(msg.sender, _eggid) == 1, "Egg doesn't belong to sender!");

        uint256 randomNumber;
        randomNumber = IRandomizer(IAddressManager(addressManagerAddress).getAddress("randomizerContractAddress")).getRandomInRange(1, 100, 
            uint256(keccak256(abi.encodePacked(msg.sender))) + _eggid);

        if (randomNumber <= 30) {
            // Hatching Rooster
            newId = IChicken_NFT(IAddressManager(addressManagerAddress).getAddress("chickenContractAddress")).hatchRooster(msg.sender, tokenIdToEggStats[_eggid].quality);
            newType = 0;
        } else if (randomNumber <= 60) {
            // Hatching Hen
            newId = IChicken_NFT(IAddressManager(addressManagerAddress).getAddress("chickenContractAddress")).hatchHen(msg.sender, tokenIdToEggStats[_eggid].quality);
            newType = 1;
        } else if (randomNumber <= 90) {
            // Hatching Item
            newId = IItem_NFT(IAddressManager(addressManagerAddress).getAddress("itemContractAddress")).hatchItem(msg.sender, tokenIdToEggStats[_eggid].quality);
            newType = 2;
        } else if (randomNumber <= 100) {
            // Hatching Spell
            newId = ISpell_NFT(IAddressManager(addressManagerAddress).getAddress("spellContractAddress")).hatchSpell(msg.sender, tokenIdToEggStats[_eggid].quality);
            newType = 3;
        }

        // burning egg
        _burn(msg.sender, _eggid, 1);
        
        delete tokenIdToEggStats[_eggid];
        delete _ownerOf[_eggid];

        emit EggHatched(msg.sender, _eggid, newType, newId, block.timestamp);
    }

    /**
     * @notice batch hatching of eggs
     * @dev calls hatchEgg for each eggId
     * @param _eggIds array of egg ids
     * @return newIds array of ids
     */
    function hatchMany(uint256[] memory _eggIds)
        public
        returns (uint256[] memory, uint256[] memory)
    {
        uint256[] memory newIds = new uint256[](_eggIds.length);
        uint256[] memory newTypes = new uint256[](_eggIds.length);

        for (uint256 i = 0; i < _eggIds.length; i++) {
            (newTypes[i], newIds[i]) = hatchEgg(_eggIds[i]);
        }

        emit HatchMany(newTypes, newIds);

        return (newTypes, newIds);
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
