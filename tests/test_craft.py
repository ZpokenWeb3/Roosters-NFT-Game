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
    network,
    accounts,
    exceptions,
)
from brownie.network.state import Chain
from brownie import reverts
from web3 import Web3
import pytest
import random


# START ======================== TESTS =================================

# Stake a rooster 1 for a fight
def test_craft_item_with_mint_sprig(deploy):
    # module wide static contracts
    (
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
    ) = deploy

    rhc_token.transfer(accounts[1], 1_000 * 10 ** 18, {"from": accounts[0]})
    rhc_token.approve(vault, 500 * 10 ** 18, {"from": accounts[1]})
    vault.deposit(1000, {"from": accounts[1]})

    vault.setReceiverAddress(accounts[0], {"from": accounts[0]})
    assert vault.getBalance(accounts[1], {"from": accounts[1]}) == 1000
    # Mint Items
    # _type, _selector,  _eggQuality, _zodiac, _req wins, _vampiric, account
    # vampiric weapon and armor
    tx_data = [0, 30, 50, 0, 0, 1, accounts[1], {"from": accounts[0]}]
    item1_1 = item_nft.mintItem.call(*tx_data)
    tx = item_nft.mintItem(*tx_data)
    item1_2 = item_nft.mintItem.call(*tx_data)
    tx = item_nft.mintItem(*tx_data)
    item2_1 = item_nft.mintItem.call(*tx_data)
    tx = item_nft.mintItem(*tx_data)
    item2_2 = item_nft.mintItem.call(*tx_data)
    tx = item_nft.mintItem(*tx_data)

    mintSprigs = [0] * 4
    tx_data = [2, 100, 50, 0, 0, 0, accounts[1], {"from": accounts[0]}]
    for i in range(4):
        mintSprigs[i] = item_nft.mintItem.call(*tx_data)
        item_nft.mintItem(*tx_data)

    tx = craft.mixWithMintSprig(item1_1, mintSprigs[0], {"from": accounts[1]})
    tx = craft.mixWithMintSprig(item1_2, mintSprigs[1], {"from": accounts[1]})
    tx = craft.mixWithMintSprig(item2_1, mintSprigs[2], {"from": accounts[1]})
    tx = craft.mixWithMintSprig(item2_2, mintSprigs[3], {"from": accounts[1]})

    assert (
        item_nft.getStats(item1_1, {"from": accounts[1]}) == (0, 54, 12, 0, 1, 1)
        or item_nft.getStats(item1_1, {"from": accounts[1]}) == (0, 30, 8, 0, 0, 1)
        or item_nft.getStats(item1_2, {"from": accounts[1]}) == (0, 54, 12, 0, 1, 1)
        or item_nft.getStats(item2_1, {"from": accounts[1]}) == (0, 54, 12, 0, 1, 1)
        or item_nft.getStats(item2_2, {"from": accounts[1]}) == (1, 30, 8, 0, 0, 1)
    )
    assert vault.getBalance(accounts[1], {"from": accounts[1]}) == 1000


def test_mix_weapon_or_armor(deploy):
    (
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
    ) = deploy

    tx_data = [0, 30, 50, 0, 0, 1, accounts[1], {"from": accounts[0]}]
    item1_1 = item_nft.mintItem.call(*tx_data)
    tx = item_nft.mintItem(*tx_data)
    tx_data = [1, 30, 50, 0, 0, 1, accounts[1], {"from": accounts[0]}]
    item1_2 = item_nft.mintItem.call(*tx_data)
    tx = item_nft.mintItem(*tx_data)
    tx_data = [0, 30, 50, 0, 0, 1, accounts[1], {"from": accounts[0]}]
    item2_1 = item_nft.mintItem.call(*tx_data)
    tx = item_nft.mintItem(*tx_data)
    tx_data = [1, 30, 50, 0, 0, 1, accounts[1], {"from": accounts[0]}]
    item2_2 = item_nft.mintItem.call(*tx_data)
    tx = item_nft.mintItem(*tx_data)
    assert item_nft.getStats(item1_1) == (0, 30, 7, 0, 0, 1)
    assert item_nft.getStats(item1_2) == (1, 30, 7, 0, 0, 1)

    tx = craft.mixWeaponOrArmor(item1_1, item2_1, {"from": accounts[1]})
    tx = craft.mixWeaponOrArmor(item1_2, item2_2, {"from": accounts[1]})
    tx.wait(1)

    assert item_nft.getStats(item2_1) == (0, 0, 0, 0, 0, 0)
    assert item_nft.getStats(item2_2) == (0, 0, 0, 0, 0, 0)
    # item bonus increased 50%
    assert item_nft.getStats(item1_1) == (0, 30, 11, 0, 0, 1)
    assert item_nft.getStats(item1_2) == (1, 30, 11, 0, 0, 1)


def test_sacrifice_chicken(deploy):
    (
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
    ) = deploy

    tx_data = [0, 30, 50, 0, 0, 1, accounts[1], {"from": accounts[0]}]
    item1_1 = item_nft.mintItem.call(*tx_data)
    tx = item_nft.mintItem(*tx_data)
    tx_data = [1, 30, 50, 0, 0, 1, accounts[1], {"from": accounts[0]}]
    item1_2 = item_nft.mintItem.call(*tx_data)
    tx = item_nft.mintItem(*tx_data)

    assert item_nft.getStats(item1_1) == (0, 30, 7, 0, 0, 1)
    assert item_nft.getStats(item1_2) == (1, 30, 7, 0, 0, 1)

    # Mint Custom Roosters
    # attack, defence, health, speed, luck, winsCounter
    tx_data = [(30, 30, 30, 30, 30, 0), accounts[1], {"from": accounts[0]}]
    rooster1 = chicken_nft.mintRooster.call(*tx_data)
    tx = chicken_nft.mintRooster(*tx_data)

    rooster2 = chicken_nft.mintRooster.call(*tx_data)
    tx = chicken_nft.mintRooster(*tx_data)
    tx.wait(1)

    tx = craft.mixSacrificeChicken(item1_1, rooster1, {"from": accounts[1]})
    tx = craft.mixSacrificeChicken(item1_2, rooster2, {"from": accounts[1]})
    tx.wait(1)

    # with reverts():
    #     chicken_nft.getStats(rooster1)
    # with reverts():
    #     chicken_nft.getStats(rooster2)

    assert item_nft.getStats(item1_1) == (0, 30, 15, 0, 0, 1)
    assert item_nft.getStats(item1_2) == (1, 30, 15, 0, 0, 1)


def test_double_sacrifice_chicken(deploy):
    (
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
    ) = deploy

    # Mint Custom Roosters
    # attack, defence, health, speed, luck, winsCounter

    tx_data = [(30, 30, 30, 30, 30, 0), accounts[1], {"from": accounts[0]}]
    rooster1 = chicken_nft.mintRooster.call(*tx_data)
    tx = chicken_nft.mintRooster(*tx_data)

    rooster2 = chicken_nft.mintRooster.call(*tx_data)
    tx = chicken_nft.mintRooster(*tx_data)
    tx.wait(1)

    newItemId = craft.mixDoubleSacrifice.call(rooster1, rooster2, {"from": accounts[1]})
    tx = craft.mixDoubleSacrifice(rooster1, rooster2, {"from": accounts[1]})
    tx.wait(1)

    assert newItemId > 0
    assert item_nft.getStats(newItemId, {"from": accounts[1]}) != (0, 0, 0, 0, 0, 0)


def test_reverts_wrong_items(deploy):
    (
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
    ) = deploy

    item1_1 = item_nft.mintItem.call(
        1, 30, 50, 0, 0, 1, accounts[1], {"from": accounts[0]}
    )
    tx = item_nft.mintItem(1, 30, 50, 0, 0, 1, accounts[1], {"from": accounts[0]})
    item1_2 = item_nft.mintItem.call(
        2, 30, 50, 0, 0, 1, accounts[1], {"from": accounts[0]}
    )
    tx = item_nft.mintItem(2, 30, 50, 0, 0, 1, accounts[1], {"from": accounts[0]})
    item1_3 = item_nft.mintItem.call(
        0, 30, 50, 0, 0, 1, accounts[1], {"from": accounts[0]}
    )
    tx = item_nft.mintItem(0, 30, 50, 0, 0, 1, accounts[1], {"from": accounts[0]})
    # Mint Custom Roosters
    # attack, defence, health, speed, luck, winsCounter

    tx_data = [(30, 30, 30, 30, 30, 0), accounts[1], {"from": accounts[0]}]
    rooster1 = chicken_nft.mintRooster.call(*tx_data)
    tx = chicken_nft.mintRooster(*tx_data)

    rooster2 = chicken_nft.mintRooster.call(*tx_data)
    tx = chicken_nft.mintRooster(*tx_data)
    tx.wait(1)

    with reverts("Chicken does not belong to sender!"):
        craft.mixDoubleSacrifice.call(rooster1, 12, {"from": accounts[1]})
    with reverts("Item does not belong to sender!"):
        craft.mixSacrificeChicken.call(rooster1, item1_1, {"from": accounts[1]})
    with reverts("Item does not belong to sender!"):
        craft.mixWeaponOrArmor.call(rooster1, rooster2, {"from": accounts[1]})
    with reverts("2nd item not a weapon or armor!"):
        craft.mixWeaponOrArmor.call(item1_1, item1_2, {"from": accounts[1]})
    with reverts("Only same type!"):
        craft.mixWeaponOrArmor.call(item1_1, item1_3, {"from": accounts[1]})
