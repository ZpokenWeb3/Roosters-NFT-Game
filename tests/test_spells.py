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

# simple owner test
def test_owner(deploy):
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

    assert (
        egg_nft.owner() == item_nft.owner()
        and chicken_nft.owner() == battle.owner()
        and bets.owner() == item_nft.owner()
        and spell_nft.owner() == battle.owner()
    )


# test set url
def test_set_url_spell_contract(deploy):
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
    spell_nft.setURI("new_url", {"from": accounts[0]})


# testing for ownership of spell
def test_owner_of_spell(deploy):
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
    spell1_1 = spell_nft.mintSpell.call(20, 50, 0, accounts[1], {"from": accounts[0]})
    tx = spell_nft.mintSpell(20, 50, 0, accounts[1], {"from": accounts[0]})
    assert spell_nft.ownerOf(spell1_1, {"from": accounts[1]}) == accounts[1]


# get spell stats
def test_get_spell_stats(deploy):
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

    assert spell_nft.getStats(1, {"from": accounts[1]}) == (20, 20, 3)


# test combination commands
def test_combination_commands_and_spells(deploy):
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

    tx_data = [(50, 70, 80, 40, 50, 3), accounts[1], {"from": accounts[0]}]
    rooster1 = chicken_nft.mintRooster.call(*tx_data)
    tx = chicken_nft.mintRooster(*tx_data)
    tx.wait(1)

    tx_data = [(51, 67, 75, 42, 55, 3), accounts[1], {"from": accounts[0]}]
    rooster2 = chicken_nft.mintRooster.call(*tx_data)
    tx = chicken_nft.mintRooster(*tx_data)

    # Mint Items
    # _type, _selector,  _eggQuality, _zodiac, _vampiric, account
    # Ankh ressurection item
    item1_1 = item_nft.mintItem.call(
        2, 4, 0, 0, 0, 0, accounts[1], {"from": accounts[0]}
    )
    tx = item_nft.mintItem(2, 4, 0, 0, 0, 0, accounts[1], {"from": accounts[0]})
    tx.wait(1)
    # Item 2 - Own speed -25%
    item2_1 = item_nft.mintItem.call(
        2, 70, 1, 0, 0, 0, accounts[1], {"from": accounts[0]}
    )
    tx = item_nft.mintItem(2, 70, 1, 0, 0, 0, accounts[1], {"from": accounts[0]})
    tx.wait(1)
    # mint spells
    spell1_1 = spell_nft.mintSpell.call(20, 50, 0, accounts[1], {"from": accounts[0]})
    tx = spell_nft.mintSpell(20, 50, 0, accounts[1], {"from": accounts[0]})
    spell1_2 = spell_nft.mintSpell.call(30, 50, 0, accounts[1], {"from": accounts[0]})
    tx = spell_nft.mintSpell(30, 50, 0, accounts[1], {"from": accounts[0]})
    spell1_3 = spell_nft.mintSpell.call(30, 50, 0, accounts[1], {"from": accounts[0]})
    tx = spell_nft.mintSpell(30, 50, 0, accounts[1], {"from": accounts[0]})
    spell2_1 = spell_nft.mintSpell.call(20, 50, 0, accounts[1], {"from": accounts[0]})
    tx = spell_nft.mintSpell(20, 50, 0, accounts[1], {"from": accounts[0]})
    spell2_2 = spell_nft.mintSpell.call(30, 50, 0, accounts[1], {"from": accounts[0]})
    tx = spell_nft.mintSpell(30, 50, 0, accounts[1], {"from": accounts[0]})

    # stake roosters
    tx_data = [
        rooster1,
        (0, 0, item1_1),
        (spell1_1, spell1_2, spell1_3),
        "A-S-S-A-S-A",
        {"from": accounts[1]},
    ]
    stake_id1 = battle.stakeRooster.call(*tx_data)
    tx = battle.stakeRooster(*tx_data)
    tx.wait(1)

    tx_data = [
        rooster2,
        (0, 0, item2_1),
        (spell2_1, spell2_2, 0),
        "S-A-S",
        {"from": accounts[1]},
    ]
    stake_id2 = battle.stakeRooster.call(*tx_data)
    tx = battle.stakeRooster(*tx_data)
    tx.wait(1)

    # setting a fight
    fight_id = battle.setFight.call(stake_id1, stake_id2, {"from": accounts[1]})
    tx = battle.setFight(stake_id1, stake_id2, {"from": accounts[1]})
    tx.wait(1)

    # wait 10 minutes
    chain.sleep(600)
    # initiate a fight
    tx = battle.initiateFight(fight_id, {"from": accounts[0]})
    assert tx.events["FightEvent"]["fightStory"][0][2] == 0
    assert tx.events["FightEvent"]["fightStory"][0][3] >= 0
    assert tx.events["FightEvent"]["fightStory"][1][2] >= 0
    assert tx.events["FightEvent"]["fightStory"][1][3] == 0
    assert tx.events["FightEvent"]["fightStory"][2][3] >= 0
    assert tx.events["FightEvent"]["fightStory"][2][2] >= 0
    assert tx.events["FightEvent"]["fightStory"][3][3] >= 0
    assert tx.events["FightEvent"]["fightStory"][3][2] == 0


# test combination commands
def test_reverts_not_enough_commands(deploy):
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

    tx_data = [(50, 70, 80, 40, 50, 3), accounts[1], {"from": accounts[0]}]
    rooster1 = chicken_nft.mintRooster.call(*tx_data)
    tx = chicken_nft.mintRooster(*tx_data)
    tx.wait(1)

    tx_data = [(51, 67, 75, 42, 55, 3), accounts[1], {"from": accounts[0]}]
    rooster2 = chicken_nft.mintRooster.call(*tx_data)
    tx = chicken_nft.mintRooster(*tx_data)

    # Mint Items
    # _type, _selector,  _eggQuality, _zodiac, _vampiric, account
    # Ankh ressurection item
    item1_1 = item_nft.mintItem.call(
        2, 4, 0, 0, 0, 0, accounts[1], {"from": accounts[0]}
    )
    tx = item_nft.mintItem(2, 4, 0, 0, 0, 0, accounts[1], {"from": accounts[0]})
    tx.wait(1)

    tx = item_nft.mintItem(2, 70, 1, 0, 0, 0, accounts[1], {"from": accounts[0]})
    tx.wait(1)
    # mint spells
    spell1_1 = spell_nft.mintSpell.call(20, 50, 0, accounts[1], {"from": accounts[0]})
    tx = spell_nft.mintSpell(20, 50, 0, accounts[1], {"from": accounts[0]})
    spell1_2 = spell_nft.mintSpell.call(30, 50, 0, accounts[1], {"from": accounts[0]})
    tx = spell_nft.mintSpell(30, 50, 0, accounts[1], {"from": accounts[0]})
    spell1_3 = spell_nft.mintSpell.call(30, 50, 0, accounts[1], {"from": accounts[0]})
    tx = spell_nft.mintSpell(30, 50, 0, accounts[1], {"from": accounts[0]})

    # stake roosters
    with reverts("Not enough commands!"):
        battle.stakeRooster.call(
            rooster1,
            (0, 0, item1_1),
            (spell1_1, spell1_2, spell1_3),
            "SA",
            {"from": accounts[1]},
        )


# test combination commands
def test_reverts_too_much_commands(deploy):
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
    tx_data = [(50, 70, 80, 40, 50, 3), accounts[1], {"from": accounts[0]}]
    rooster1 = chicken_nft.mintRooster.call(*tx_data)
    tx = chicken_nft.mintRooster(*tx_data)
    tx.wait(1)

    # Mint Items
    # _type, _selector,  _eggQuality, _zodiac, _vampiric, account
    # Ankh ressurection item
    item1_1 = item_nft.mintItem.call(
        2, 4, 0, 0, 0, 0, accounts[1], {"from": accounts[0]}
    )
    tx = item_nft.mintItem(2, 4, 0, 0, 0, 0, accounts[1], {"from": accounts[0]})
    tx.wait(1)

    tx = item_nft.mintItem(2, 70, 1, 0, 0, 0, accounts[1], {"from": accounts[0]})
    tx.wait(1)
    # mint spells
    spell1_1 = spell_nft.mintSpell.call(20, 50, 0, accounts[1], {"from": accounts[0]})
    tx = spell_nft.mintSpell(20, 50, 0, accounts[1], {"from": accounts[0]})
    spell1_2 = spell_nft.mintSpell.call(30, 50, 0, accounts[1], {"from": accounts[0]})
    tx = spell_nft.mintSpell(30, 50, 0, accounts[1], {"from": accounts[0]})
    spell1_3 = spell_nft.mintSpell.call(30, 50, 0, accounts[1], {"from": accounts[0]})
    tx = spell_nft.mintSpell(30, 50, 0, accounts[1], {"from": accounts[0]})

    # stake roosters
    with reverts("Too many commands!"):
        battle.stakeRooster.call(
            rooster1,
            (0, 0, item1_1),
            (spell1_1, spell1_2, spell1_3),
            "SASAASS",
            {"from": accounts[1]},
        )


# test combination commands
def test_reverts_not_missing_attacks(deploy):
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
    tx_data = [(50, 70, 80, 40, 50, 3), accounts[1], {"from": accounts[0]}]
    rooster1 = chicken_nft.mintRooster.call(*tx_data)
    tx = chicken_nft.mintRooster(*tx_data)
    tx.wait(1)

    tx_data = [(51, 67, 75, 42, 55, 3), accounts[1], {"from": accounts[0]}]
    rooster2 = chicken_nft.mintRooster.call(*tx_data)
    tx = chicken_nft.mintRooster(*tx_data)

    # Mint Items
    # _type, _selector,  _eggQuality, _zodiac, _vampiric, account
    # Ankh ressurection item
    item1_1 = item_nft.mintItem.call(
        2, 4, 0, 0, 0, 0, accounts[1], {"from": accounts[0]}
    )
    tx = item_nft.mintItem(2, 4, 0, 0, 0, 0, accounts[1], {"from": accounts[0]})
    tx.wait(1)

    # mint spells
    spell1_1 = spell_nft.mintSpell.call(20, 50, 0, accounts[1], {"from": accounts[0]})
    tx = spell_nft.mintSpell(20, 50, 0, accounts[1], {"from": accounts[0]})
    spell1_2 = spell_nft.mintSpell.call(30, 50, 0, accounts[1], {"from": accounts[0]})
    tx = spell_nft.mintSpell(30, 50, 0, accounts[1], {"from": accounts[0]})

    # stake roosters
    with reverts("There must be at least one attack!"):
        battle.stakeRooster.call(
            rooster1,
            (0, 0, item1_1),
            (spell1_1, spell1_2, 0),
            "S-S-S-S-S-S",
            {"from": accounts[1]},
        )

    # Ankh ressurection - 1 rooster, Caffeine, Low egg quality - 2 rooster
    # (160, 156, 0, 11, 50, 0, 0), (152, 134, 8, 0, 0, 100, 1), (119, 126, 0, 10, 100, 0, 7), (111, 103, 9, 0, 0, 100, 6),(70, 94, 0, 0, 100, 100, 8), (33, 53, 8, 0, 0, 100, 9)
    # Ward Item, Low egg quality - 1 rooster, Hashish breath, Low egg quality - 2 rooster
    # (160, 156, 0, 0, 50, 200, 0), (102, 134, 0, 0, 100, 100, 1), (71, 104, 0, 0, 100, 52, 7), (49, 70, 0, 0, 185, 100, 6), (10, 17, 0, 0, 52, 197, 8)
    # Ward Item, High egg quality - 1 rooster, Hashish breath, Low egg quality - 2 rooster
    # (160, 156, 0, 23, 50, 0, 0), (152, 134, 20, 0, 0, 100, 1), (116, 126, 0, 22, 100, 0, 7), (108, 104, 21, 22, 0, 0, 6), (99, 115, 0, 0, 100, 100, 8), (63, 71, 20, 0, 0, 100, 9), (27, 61, 0, 23, 173, 0, 7)
    # Caffeine, High egg quality - 1 rooster, Hashish breath, Low egg quality - 2 rooster
    # (160, 156, 0, 23, 50, 0, 0), (152, 134, 20, 0, 0, 100, 1), (116, 126, 0, 22, 100, 0, 7), (108, 108, 21, 22, 0, 0, 6), (99, 120, 0, 0, 100, 100, 8), (63, 79, 20, 0, 0, 100, 9), (27, 69, 0, 23, 192, 0, 7), (16, 1, 19, 0, 0, 100, 5)
    # Caffeine, High egg quality - 1 rooster, Hashish breath, High egg quality - 2 rooster, Spells for speed + defence
    # (160, 156, 0, 0, 50, 200, 0), (102, 134, 20, 22, 0, 0, 1), (94, 126, 0, 0, 100, 100, 7), (56, 90, 20, 21, 0, 0, 6), (47, 81, 0, 0, 178, 100, 8), (4, 29, 19, 22, 0, 0, 9)
