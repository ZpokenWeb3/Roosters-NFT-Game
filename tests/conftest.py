from brownie import (
    NFT_Rooster_Battle,
    Battle_Lib,
    Egg_NFT,
    Chicken_NFT,
    Item_NFT,
    Roosters_Bets,
    Spell_NFT,
    Randomizer,
    RedHotCockToken,
    RHC_Vault,
    Arena_Queue,
    Craft,
    AddressManager,
    network,
    accounts,
    exceptions,
)
from brownie.network.state import Chain
from web3 import Web3
import pytest
import random


@pytest.fixture(scope="module")
def deploy():

    network.priority_fee(1_000_000_000)
    network.max_fee(10_000_000_000)
    network.gas_limit(16_000_000)

    # Deploy contracts for test module
    egg_nft = Egg_NFT.deploy({"from": accounts[0]})
    chicken_nft = Chicken_NFT.deploy({"from": accounts[0]})
    item_nft = Item_NFT.deploy({"from": accounts[0]})
    spell_nft = Spell_NFT.deploy({"from": accounts[0]})
    battle_lib = Battle_Lib.deploy({"from": accounts[0]})
    battle = NFT_Rooster_Battle.deploy(battle_lib, {"from": accounts[0]})
    rhc_token = RedHotCockToken.deploy({"from": accounts[0]})
    vault = RHC_Vault.deploy({"from": accounts[0]})
    bets = Roosters_Bets.deploy({"from": accounts[0]})
    arena = Arena_Queue.deploy({"from": accounts[0]})
    craft = Craft.deploy({"from": accounts[0]})
    randomizer = Randomizer.deploy({"from": accounts[0]})
    address_manager = AddressManager.deploy({"from": accounts[0]})

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

    # egg_nft.setAllAddresses(allAddresses, {"from": accounts[0]})
    # chicken_nft.setAllAddresses(allAddresses, {"from": accounts[0]})
    # item_nft.setAllAddresses(allAddresses, {"from": accounts[0]})
    # spell_nft.setAllAddresses(allAddresses, {"from": accounts[0]})
    # battle_lib.setAllAddresses(allAddresses, {"from": accounts[0]})
    # battle.setAllAddresses(allAddresses, {"from": accounts[0]})
    # vault.setAllAddresses(allAddresses, {"from": accounts[0]})
    # bets.setAllAddresses(allAddresses, {"from": accounts[0]})
    # craft.setAllAddresses(allAddresses, {"from": accounts[0]})
    # arena.setAllAddresses(allAddresses, {"from": accounts[0]})

    egg_nft.setAddressManager(address_manager.address, {"from": accounts[0]})
    chicken_nft.setAddressManager(address_manager.address, {"from": accounts[0]})
    item_nft.setAddressManager(address_manager.address, {"from": accounts[0]})
    spell_nft.setAddressManager(address_manager.address, {"from": accounts[0]})
    battle_lib.setAddressManager(address_manager.address, {"from": accounts[0]})
    battle.setAddressManager(address_manager.address, {"from": accounts[0]})
    vault.setAddressManager(address_manager.address, {"from": accounts[0]})
    bets.setAddressManager(address_manager.address, {"from": accounts[0]})
    craft.setAddressManager(address_manager.address, {"from": accounts[0]})
    arena.setAddressManager(address_manager.address, {"from": accounts[0]})

    address_manager.setAllAddresses(allAddresses, {"from": accounts[0]})

    vault.setDepositToken(rhc_token, {"from": accounts[0]})
    vault.setReceiverAddress(accounts[1].address, {"from": accounts[0]})

    return (
        egg_nft,
        chicken_nft,
        item_nft,
        spell_nft,
        battle,
        rhc_token,
        vault,
        bets,
        arena,
        craft,
        randomizer,
    )
