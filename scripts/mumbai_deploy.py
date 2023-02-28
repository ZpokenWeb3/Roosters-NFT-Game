from brownie import (
    Egg_NFT,
    Chicken_NFT,
    Item_NFT,
    Spell_NFT,
    NFT_Rooster_Battle,
    Battle_Lib,
    Randomizer,
    RedHotCockToken,
    RHC_Vault,
    Roosters_Bets,
    Arena_Queue,
    Craft,
    AddressManager,
    Contract,
    network,
    config,
    accounts,
)

from web3 import Web3
import time


def main():

    # Account 3
    account = accounts.add(config["wallets"]["from_key3"])
    receiver = accounts.add(config["wallets"]["from_key"])

    # Depoloying RHC token
    rhc_token = RedHotCockToken.deploy({"from": account})

    # Deploy new contracts
    # ============================================================
    egg_nft = Egg_NFT.deploy({"from": account})
    chicken_nft = Chicken_NFT.deploy({"from": account})
    item_nft = Item_NFT.deploy({"from": account})
    spell_nft = Spell_NFT.deploy({"from": account})
    battle_lib = Battle_Lib.deploy({"from": account})
    battle = NFT_Rooster_Battle.deploy(battle_lib, {"from": account})
    vault = RHC_Vault.deploy({"from": account})
    bets = Roosters_Bets.deploy({"from": account})
    arena = Arena_Queue.deploy({"from": account})
    craft = Craft.deploy({"from": account})
    randomizer = Randomizer.deploy({"from": account})
    address_manager = AddressManager.deploy({"from": account})

    # struct AllAddresses {
    #     address eggContractAddress;
    #     address chickenContractAddress;
    #     address itemContractAddress;
    #     address spellContractAddress;
    #     address battleContractAddress;
    #     address vaultContractAddress;
    #     address betsContractAddress;
    #     address arenaContractAddress;
    #     address craftContractAddress;
    #     address randomizerContractAddress;
    # }

    allAddresses = [
        egg_nft.address,
        chicken_nft.address,
        item_nft.address,
        spell_nft.address,
        battle.address,
        vault.address,
        bets.address,
        arena.address,
        craft.address,
        randomizer.address,
    ]

    egg_nft.setAddressManager(address_manager.address, {"from": account})
    chicken_nft.setAddressManager(address_manager.address, {"from": account})
    item_nft.setAddressManager(address_manager.address, {"from": account})
    spell_nft.setAddressManager(address_manager.address, {"from": account})
    battle_lib.setAddressManager(address_manager.address, {"from": account})
    battle.setAddressManager(address_manager.address, {"from": account})
    vault.setAddressManager(address_manager.address, {"from": account})
    bets.setAddressManager(address_manager.address, {"from": account})
    craft.setAddressManager(address_manager.address, {"from": account})
    arena.setAddressManager(address_manager.address, {"from": account})

    address_manager.setAllAddresses(allAddresses, {"from": account})

    print("-----------ALL ADDRESSES---------")
    print("eggContractAddress:", address_manager.getAddress("eggContractAddress"))
    print(
        "chickenContractAddress:", address_manager.getAddress("chickenContractAddress")
    )
    print("itemContractAddres:", address_manager.getAddress("itemContractAddress"))
    print("spellContractAddress:", address_manager.getAddress("spellContractAddress"))
    print("battleContractAddress:", address_manager.getAddress("battleContractAddress"))
    print("vaultContractAddress:", address_manager.getAddress("vaultContractAddress"))
    print("betsContractAddress:", address_manager.getAddress("betsContractAddress"))
    print("arenaContractAddress:", address_manager.getAddress("arenaContractAddress"))
    print("craftContractAddress:", address_manager.getAddress("craftContractAddress"))
    print(
        "randomizerContractAddress:",
        address_manager.getAddress("randomizerContractAddress"),
    )
    print("AddressManager:", address_manager.address)
    print("-----------ALL ADDRESSES---------")
    print()

    vault.setDepositToken(rhc_token, {"from": account})
    vault.setReceiverAddress(receiver.address, {"from": account})

    time.sleep(2)


if __name__ == "__main__":
    main()
    # run with
    # brownie run .\scripts\mumbai_deploy.py --network mumbai
