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
    reverts,
)
from brownie.network.state import Chain
from web3 import Web3
import pytest
import random

# START ======================== TESTS =================================


def test_update_max_tree_size(deploy):
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

    arena.updateMaxTreeSize(5, {"from": accounts[0]})


def test_get_max_queue_size(deploy):
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

    assert arena.getMaxQueueSize({"from": accounts[0]}) == 5


def test_arena_queue_succesfull_insert(deploy):
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

    rhc_token.approve(vault.address, 1_000 * 10 ** 18, {"from": accounts[0]})
    vault.deposit(1_000 * 10 ** 18, {"from": accounts[0]})

    # Mint Custom Roosters
    # attack, defence, health, speed, luck, winsCounter
    rooster1 = chicken_nft.mintRooster.call(
        (50, 70, 80, 40, 50, 3), accounts[0], {"from": accounts[0]}
    )
    tx = chicken_nft.mintRooster(
        (50, 70, 80, 40, 50, 3), accounts[0], {"from": accounts[0]}
    )
    tx.wait(1)

    rooster2 = chicken_nft.mintRooster.call(
        (50, 70, 80, 40, 50, 3), accounts[0], {"from": accounts[0]}
    )
    tx = chicken_nft.mintRooster(
        (50, 70, 80, 40, 50, 3), accounts[0], {"from": accounts[0]}
    )
    tx.wait(1)

    rooster3 = chicken_nft.mintRooster.call(
        (50, 70, 80, 40, 50, 3), accounts[0], {"from": accounts[0]}
    )
    tx = chicken_nft.mintRooster(
        (50, 70, 80, 40, 50, 3), accounts[0], {"from": accounts[0]}
    )
    tx.wait(1)

    # Mint Items
    # _type, _selector,  _eggQuality, _zodiac, _req wins, _vampiric, account
    # vampiric weapon and armor

    item1_1 = item_nft.mintItem.call(
        0, 30, 50, 0, 0, 1, accounts[0], {"from": accounts[0]}
    )
    tx = item_nft.mintItem(0, 30, 50, 0, 0, 1, accounts[0], {"from": accounts[0]})
    item1_2 = item_nft.mintItem.call(
        1, 30, 50, 0, 0, 1, accounts[0], {"from": accounts[0]}
    )
    tx = item_nft.mintItem(1, 30, 50, 0, 0, 1, accounts[0], {"from": accounts[0]})
    item2_1 = item_nft.mintItem.call(
        0, 30, 50, 0, 0, 1, accounts[0], {"from": accounts[0]}
    )
    tx = item_nft.mintItem(0, 30, 50, 0, 0, 1, accounts[0], {"from": accounts[0]})
    item2_2 = item_nft.mintItem.call(
        1, 30, 50, 0, 0, 1, accounts[0], {"from": accounts[0]}
    )
    tx = item_nft.mintItem(1, 30, 50, 0, 0, 1, accounts[0], {"from": accounts[0]})

    # Mint Spells
    # _selector,  _eggQuality, _req wins, account
    spell1_1 = spell_nft.mintSpell.call(20, 50, 0, accounts[0], {"from": accounts[0]})
    tx = spell_nft.mintSpell(20, 50, 0, accounts[0], {"from": accounts[0]})
    spell1_2 = spell_nft.mintSpell.call(30, 50, 0, accounts[0], {"from": accounts[0]})
    tx = spell_nft.mintSpell(30, 50, 0, accounts[0], {"from": accounts[0]})
    spell2_1 = spell_nft.mintSpell.call(20, 50, 0, accounts[0], {"from": accounts[0]})
    tx = spell_nft.mintSpell(20, 50, 0, accounts[0], {"from": accounts[0]})
    spell2_2 = spell_nft.mintSpell.call(30, 50, 0, accounts[0], {"from": accounts[0]})
    tx = spell_nft.mintSpell(30, 50, 0, accounts[0], {"from": accounts[0]})

    # stake roosters

    stake_id1 = battle.stakeRooster.call(
        rooster1,
        (item1_1, item1_2, 0),
        (spell1_1, spell1_2, 0),
        "A-S",
        {"from": accounts[0]},
    )
    tx = battle.stakeRooster(
        rooster1,
        (item1_1, item1_2, 0),
        (spell1_1, spell1_2, 0),
        "A-S",
        {"from": accounts[0]},
    )
    tx.wait(1)

    stake_id2 = battle.stakeRooster.call(
        rooster2,
        (item2_1, item2_2, 0),
        (spell2_1, spell2_2, 0),
        "A-S",
        {"from": accounts[0]},
    )
    tx = battle.stakeRooster(
        rooster2,
        (item2_1, item2_2, 0),
        (spell2_1, spell2_2, 0),
        "A-S",
        {"from": accounts[0]},
    )
    tx.wait(1)

    stake_id3 = battle.stakeRooster.call(
        rooster3,
        (0, 0, 0),
        (0, 0, 0),
        "A-A",
        {"from": accounts[0]},
    )
    tx = battle.stakeRooster(
        rooster3,
        (0, 0, 0),
        (0, 0, 0),
        "A-A",
        {"from": accounts[0]},
    )
    tx.wait(1)

    assert stake_id1 == 1
    assert stake_id2 == 2
    assert stake_id3 == 3


def test_get_queue_count(deploy):
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
    assert arena.getQueueCount({"from": accounts[0]}) == 3


def test_find_opponent(deploy):
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

    chain = Chain()
    rooster1 = chicken_nft.mintRooster.call(
        (51, 68, 82, 38, 51, 3), accounts[0], {"from": accounts[0]}
    )
    tx = chicken_nft.mintRooster(
        (51, 68, 82, 38, 51, 3), accounts[0], {"from": accounts[0]}
    )
    tx.wait(1)

    # Mint Items
    # _type, _selector,  _eggQuality, _zodiac, _req wins, _vampiric, account
    # vampiric weapon and armor
    item1_1 = item_nft.mintItem.call(
        0, 30, 50, 0, 0, 1, accounts[0], {"from": accounts[0]}
    )
    tx = item_nft.mintItem(0, 30, 50, 0, 0, 1, accounts[0], {"from": accounts[0]})
    item1_2 = item_nft.mintItem.call(
        1, 30, 50, 0, 0, 1, accounts[0], {"from": accounts[0]}
    )
    tx = item_nft.mintItem(1, 30, 50, 0, 0, 1, accounts[0], {"from": accounts[0]})

    # Mint Spells
    # _selector,  _eggQuality, _req wins, account
    spell1_1 = spell_nft.mintSpell.call(20, 50, 0, accounts[0], {"from": accounts[0]})
    tx = spell_nft.mintSpell(20, 50, 0, accounts[0], {"from": accounts[0]})
    spell1_2 = spell_nft.mintSpell.call(30, 50, 0, accounts[0], {"from": accounts[0]})
    tx = spell_nft.mintSpell(30, 50, 0, accounts[0], {"from": accounts[0]})

    # stake roosters
    stake_id4 = battle.stakeRooster.call(
        rooster1,
        (item1_1, item1_2, 0),
        (spell1_1, spell1_2, 0),
        "A-S",
        {"from": accounts[0]},
    )
    tx = battle.stakeRooster(
        rooster1,
        (item1_1, item1_2, 0),
        (spell1_1, spell1_2, 0),
        "A-S",
        {"from": accounts[0]},
    )
    tx.wait(1)

    assert stake_id4 == 4
    # wait 10 minutes
    chain.sleep(1201)

    fightId = battle.findOponentInArenaQueue.call(4, {"from": accounts[0]})
    tx = battle.findOponentInArenaQueue(4, {"from": accounts[0]})
    tx.wait(1)

    assert fightId == 1
    assert arena.getQueueCount({"from": accounts[0]}) == 2


def test_revert_updating_max_tree_size_with_over_participants(deploy):
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

    with reverts():
        arena.updateMaxTreeSize.call(1, {"from": accounts[0]})


def test_last_stake_with_equally_roosters(deploy):
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

    rooster1 = chicken_nft.mintRooster.call(
        (49, 71, 78, 41, 50, 3), accounts[0], {"from": accounts[0]}
    )
    tx = chicken_nft.mintRooster(
        (49, 71, 78, 41, 50, 3), accounts[0], {"from": accounts[0]}
    )
    tx.wait(1)

    # Mint Items
    # _type, _selector,  _eggQuality, _zodiac, _req wins, _vampiric, account
    # vampiric weapon and armor
    item1_1 = item_nft.mintItem.call(
        0, 30, 50, 0, 0, 1, accounts[0], {"from": accounts[0]}
    )
    tx = item_nft.mintItem(0, 30, 50, 0, 0, 1, accounts[0], {"from": accounts[0]})
    item1_2 = item_nft.mintItem.call(
        1, 30, 50, 0, 0, 1, accounts[0], {"from": accounts[0]}
    )
    tx = item_nft.mintItem(1, 30, 50, 0, 0, 1, accounts[0], {"from": accounts[0]})

    # Mint Spells
    # _selector,  _eggQuality, _req wins,
    spell1_1 = spell_nft.mintSpell.call(20, 50, 0, accounts[0], {"from": accounts[0]})
    tx = spell_nft.mintSpell(20, 50, 0, accounts[0], {"from": accounts[0]})
    spell1_2 = spell_nft.mintSpell.call(30, 50, 0, accounts[0], {"from": accounts[0]})
    tx = spell_nft.mintSpell(30, 50, 0, accounts[0], {"from": accounts[0]})

    # stake roosters
    stake_id5 = battle.stakeRooster.call(
        rooster1,
        (item1_1, item1_2, 0),
        (spell1_1, spell1_2, 0),
        "A-S",
        {"from": accounts[0]},
    )
    tx = battle.stakeRooster(
        rooster1,
        (item1_1, item1_2, 0),
        (spell1_1, spell1_2, 0),
        "A-S",
        {"from": accounts[0]},
    )
    tx.wait(1)

    assert stake_id5 == 5

    fightId = battle.findOponentInArenaQueue.call(stake_id5, {"from": accounts[0]})
    tx = battle.findOponentInArenaQueue(stake_id5, {"from": accounts[0]})
    tx.wait(1)

    assert fightId == 2
    assert arena.getQueueCount({"from": accounts[0]}) == 1


def test_success_updating_max_tree_size_with_over_participants(deploy):
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

    arena.updateMaxTreeSize(10, {"from": accounts[0]})
    for i in range(10):
        rooster1 = chicken_nft.mintRooster.call(
            (49, 71, 78, 41, 50, 3), accounts[0], {"from": accounts[0]}
        )
        tx = chicken_nft.mintRooster(
            (49, 71, 78, 41, 50, 3), accounts[0], {"from": accounts[0]}
        )
        tx.wait(1)

        # stake roosters
        battle.stakeRooster(
            rooster1,
            (0, 0, 0),
            (0, 0, 0),
            "A-S",
            {"from": accounts[0]},
        )

    arena.updateMaxTreeSize(8, {"from": accounts[0]})
    fightId = battle.findOponentInArenaQueue.call(7, {"from": accounts[0]})
    tx = battle.findOponentInArenaQueue(7, {"from": accounts[0]})
    tx.wait(1)

    assert fightId == 3
    assert arena.getMaxQueueSize({"from": accounts[0]}) == 8


def test_mirror_fight_without_opponents(deploy):
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

    chain = Chain()

    rooster1 = chicken_nft.mintRooster.call(
        (2, 4, 2, 2, 2, 0), accounts[1], {"from": accounts[0]}
    )
    tx = chicken_nft.mintRooster((2, 4, 2, 2, 2, 0), accounts[1], {"from": accounts[0]})
    tx.wait(1)

    stake_id = battle.stakeRooster.call(
        rooster1, (0, 0, 0), (0, 0, 0), "A-A", {"from": accounts[1]}
    )
    tx = battle.stakeRooster(
        rooster1, (0, 0, 0), (0, 0, 0), "A-A", {"from": accounts[1]}
    )
    tx.wait(1)

    fight_id = battle.findOponentInArenaQueue.call(stake_id, {"from": accounts[1]})
    tx = battle.findOponentInArenaQueue(stake_id, {"from": accounts[1]})

    assert fight_id == 4
    chain.sleep(601)
    tx = battle.initiateFight(fight_id, {"from": accounts[1]})
    assert tx.events["FightEvent"]["fightData"][0] == 16
