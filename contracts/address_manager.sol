// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract AddressManager is Ownable {


    event AddressSet(string indexed _name, address _newAddress, address _oldAddress);

    struct AllAddresses {
        address eggContractAddress;
        address chickenContractAddress;
        address itemContractAddress;
        address spellContractAddress;
        address battleContractAddress;
        address vaultContractAddress;
        address betsContractAddress;
        address arenaContractAddress;
        address craftContractAddress;
        address randomizerContractAddress;
    }

    AllAddresses internal allAddresses;

    mapping(bytes32 => address) private addresses;

    /**
     * Changes the address associated with a particular name.
     * @param _name String name to associate an address with.
     * @param _address Address to associate with the name.
     */
    function setAddress(string memory _name, address _address) external onlyOwner {
        _setAddress(_name, _address);
    }

    function _setAddress(string memory _name, address _address) private {
        bytes32 nameHash = _getNameHash(_name);
        address oldAddress = addresses[nameHash];

        if (_address != oldAddress) {
            addresses[nameHash] = _address;
            emit AddressSet(_name, _address, oldAddress);
        }
        
    }

    /**
     * Retrieves the address associated with a given name.
     * @param _name Name to retrieve an address for.
     * @return Address associated with the given name.
     */
    function getAddress(string memory _name) external view returns (address) {
        return addresses[_getNameHash(_name)];
    }

    /**
     * @notice Set all addresses
     * @param _allAddresses struct AllAddresses
     *struct AllAddresses {
     *  address eggContractAddress;
     *  address chickenContractAddress;
     *  address itemContractAddress;
     *  address spellContractAddress;
     *  address battleContractAddress;
     *  address vaultContractAddress;
     *  address betsContractAddress;
     *  address arenaContractAddress;
     *  address craftContractAddress;
     *  address randomizerContractAddress;}
     */
    function setAllAddresses(AllAddresses memory _allAddresses) public onlyOwner {
      allAddresses = _allAddresses;

      _setAddress("eggContractAddress", _allAddresses.eggContractAddress);
      _setAddress("chickenContractAddress", _allAddresses.chickenContractAddress);
      _setAddress("itemContractAddress", _allAddresses.itemContractAddress);
      _setAddress("spellContractAddress", _allAddresses.spellContractAddress);
      _setAddress("battleContractAddress", _allAddresses.battleContractAddress);
      _setAddress("vaultContractAddress", _allAddresses.vaultContractAddress);
      _setAddress("betsContractAddress", _allAddresses.betsContractAddress);
      _setAddress("arenaContractAddress", _allAddresses.arenaContractAddress);
      _setAddress("craftContractAddress", _allAddresses.craftContractAddress);
      _setAddress("randomizerContractAddress", _allAddresses.randomizerContractAddress);
      
    }

    /**
     * Computes the hash of a name.
     * @param _name Name to compute a hash for.
     * @return Hash of the given name.
     */
    function _getNameHash(string memory _name) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_name));
    }


}