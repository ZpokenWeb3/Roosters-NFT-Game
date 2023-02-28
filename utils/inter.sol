// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "interfaces/iaddress_manager.sol";

contract Interconnected is Ownable {

  address public addressManagerAddress;

  function setAddressManager(address _addressManagerAddress) public onlyOwner {
    addressManagerAddress = _addressManagerAddress;
  }

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

  function _updateAllAddresses() internal {
    allAddresses.eggContractAddress = IAddressManager(addressManagerAddress).getAddress("eggContractAddress");
    allAddresses.chickenContractAddress = IAddressManager(addressManagerAddress).getAddress("chickenContractAddress");
    allAddresses.itemContractAddress = IAddressManager(addressManagerAddress).getAddress("itemContractAddress");
    allAddresses.spellContractAddress = IAddressManager(addressManagerAddress).getAddress("spellContractAddress");
    allAddresses.battleContractAddress = IAddressManager(addressManagerAddress).getAddress("battleContractAddress");
    allAddresses.vaultContractAddress = IAddressManager(addressManagerAddress).getAddress("vaultContractAddress");
    allAddresses.betsContractAddress = IAddressManager(addressManagerAddress).getAddress("betsContractAddress");
    allAddresses.arenaContractAddress = IAddressManager(addressManagerAddress).getAddress("arenaContractAddress");
    allAddresses.craftContractAddress = IAddressManager(addressManagerAddress).getAddress("craftContractAddress");
    allAddresses.randomizerContractAddress = IAddressManager(addressManagerAddress).getAddress("randomizerContractAddress");
  }

  modifier onlyEggContract {
    require(msg.sender == IAddressManager(addressManagerAddress).getAddress("eggContractAddress"));
    _;
  }

  modifier onlyChickenContract {
    require(msg.sender == IAddressManager(addressManagerAddress).getAddress("chickenContractAddress"));
    _;
  }

  modifier onlyBattleContract {
    require(msg.sender == IAddressManager(addressManagerAddress).getAddress("battleContractAddress"));
    _;
  }

  modifier onlyChickenOrBattleContracts {
    require(msg.sender == IAddressManager(addressManagerAddress).getAddress("chickenContractAddress") 
    || msg.sender == IAddressManager(addressManagerAddress).getAddress("battleContractAddress"));
    _;
  }

  modifier onlyBetsContract {
    require(msg.sender == IAddressManager(addressManagerAddress).getAddress("betsContractAddress"));
    _;
  }

  modifier onlyCraftContract {
    require(msg.sender == IAddressManager(addressManagerAddress).getAddress("craftContractAddress"));
    _;
  }

  // /**
  //   * @notice Set all addresses
  //   * @param _allAddresses struct AllAddresses
  //   *struct AllAddresses {
  //   *  address eggContractAddress;
  //   *  address chickenContractAddress;
  //   *  address itemContractAddress;
  //   *  address spellContractAddress;
  //   *  address battleContractAddress;
  //   *  address vaultContractAddress;
  //   *  address betsContractAddress;
  //   *  address arenaContractAddress;
  //   *  address craftContractAddress;
  //   *  address randomizerContractAddress;}
  //   */
  // function setAllAddresses(AllAddresses memory _allAddresses) public onlyOwner {
  //   allAddresses = _allAddresses;
  // }

}