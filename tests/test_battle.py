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
def test_stake_rooster1_for_a_fight(deploy):
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

    # Mint Custom Roosters
    # attack, defence, health, speed, luck, winsCounter
    tx_data = [(30, 30, 30, 30, 30, 0), accounts[1], {"from": accounts[0]}]
    rooster1 = chicken_nft.mintRooster.call(*tx_data)
    tx = chicken_nft.mintRooster(*tx_data)
    tx.wait(1)

    # Mint Items
    # _type, _selector,  _eggQuality, _zodiac, _vampiric, account
    # Item 1 - HP +25%
    tx_data = [2, 70, 50, 0, 0, 0, accounts[1], {"from": accounts[0]}]
    item1_1 = item_nft.mintItem.call(*tx_data)
    tx = item_nft.mintItem(*tx_data)
    tx.wait(1)

    # stake roosters
    tx_data = [rooster1, (0, 0, item1_1), (0, 0, 0), "A-A", {"from": accounts[1]}]
    stake_id1 = battle.stakeRooster.call(*tx_data)
    tx = battle.stakeRooster(*tx_data)
    tx.wait(1)

    tx = item_nft.isStaked(item1_1, {"from": accounts[1]})

    assert tx == True
    assert stake_id1 == 1


# Stake a much powerfull rooster for a fight
def test_stake_powerfull_rooster_for_a_fight(deploy):
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

    tx_data = [(40, 40, 40, 40, 40, 0), accounts[1], {"from": accounts[0]}]
    rooster2 = chicken_nft.mintRooster.call(*tx_data)
    tx = chicken_nft.mintRooster(*tx_data)
    tx.wait(1)

    # Item 2 - HP +25%
    tx_data = [2, 70, 50, 0, 0, 0, accounts[1], {"from": accounts[0]}]
    item2_1 = item_nft.mintItem.call(*tx_data)
    tx = item_nft.mintItem(*tx_data)
    tx.wait(1)

    tx_data = [rooster2, (0, 0, item2_1), (0, 0, 0), "A-A", {"from": accounts[1]}]
    stake_id2 = battle.stakeRooster.call(*tx_data)
    tx = battle.stakeRooster(*tx_data)
    tx.wait(1)

    assert stake_id2 == 2


# Set a rooster fight
def test_revert_set_a_rooster_fight(deploy):
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
    # setting a fight
    with reverts("Fight is not fair!"):
        battle.setFight.call(1, 2, {"from": accounts[1]})


# Stake a rooster 2 for a fight
def test_stake_rooster2_for_a_fight(deploy):
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

    tx_data = [(31, 31, 31, 31, 31, 0), accounts[1], {"from": accounts[0]}]
    rooster2 = chicken_nft.mintRooster.call(*tx_data)
    tx = chicken_nft.mintRooster(*tx_data)
    tx.wait(1)

    # Item 2 - HP +25%
    tx_data = [2, 70, 50, 0, 0, 0, accounts[1], {"from": accounts[0]}]
    item2_1 = item_nft.mintItem.call(*tx_data)
    tx = item_nft.mintItem(*tx_data)
    tx.wait(1)

    tx_data = [rooster2, (0, 0, item2_1), (0, 0, 0), "A-A", {"from": accounts[1]}]
    stake_id3 = battle.stakeRooster.call(*tx_data)
    tx = battle.stakeRooster(*tx_data)
    tx.wait(1)

    assert stake_id3 == 3


# Set a rooster fight
def test_set_a_rooster_fight(deploy):
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
    # setting a fight
    fight_id = battle.setFight.call(1, 3, {"from": accounts[1]})
    battle.setFight(1, 3, {"from": accounts[1]})

    assert fight_id == 1


# Initiate a fight
@pytest.mark.skip_coverage
def test_initiate_a_rooster_fight(deploy):
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
    # wait 10 minutes
    chain.sleep(600)
    # initiate a fight
    tx = battle.initiateFight(1, {"from": accounts[1]})

    assert tx.events["FightEvent"]["fightData"][3] != 0


# get fight data
def test_get_fight_data(deploy):
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
    stakeId1 = 1
    stakeId2 = 3

    fight_data = battle.getFightData(1, {"from": accounts[1]})
    assert fight_data[0] == stakeId1
    assert fight_data[1] == stakeId2


# Stake a rooster for a fight and unstake
def test_stake_rooster_for_a_fight_and_unstake(deploy):
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

    tx_data = [(50, 50, 50, 50, 50, 0), accounts[1], {"from": accounts[0]}]
    rooster2 = chicken_nft.mintRooster.call(*tx_data)
    tx = chicken_nft.mintRooster(*tx_data)
    tx.wait(1)

    tx_data = [2, 50, 70, 0, 0, 0, accounts[1], {"from": accounts[0]}]
    item2_1 = item_nft.mintItem.call(*tx_data)
    tx = item_nft.mintItem(*tx_data)
    tx.wait(1)

    tx_data = [rooster2, (0, 0, item2_1), (0, 0, 0), "A-A", {"from": accounts[1]}]
    stake_id4 = battle.stakeRooster.call(*tx_data)
    tx = battle.stakeRooster(*tx_data)
    tx.wait(1)

    assert stake_id4 == 4

    tx = battle.unstakeRoosterAndItems(stake_id4, {"from": accounts[1]})
    tx.wait(1)

    assert item_nft.isStaked(item2_1) == False


# Stake a much powerfull rooster for a fight
def test_revert_stake_rooster_incorrect_item(deploy):
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

    tx_data = [(40, 40, 40, 40, 40, 0), accounts[1], {"from": accounts[0]}]
    rooster2 = chicken_nft.mintRooster.call(*tx_data)
    tx = chicken_nft.mintRooster(*tx_data)
    tx.wait(1)

    # Item 2 - HP +25%
    tx_data = [1, 70, 50, 0, 0, 0, accounts[1], {"from": accounts[0]}]
    item2_1 = item_nft.mintItem.call(*tx_data)
    tx = item_nft.mintItem(*tx_data)
    tx.wait(1)

    with reverts("Incorrect item type in a slot!"):
        battle.stakeRooster.call(
            rooster2, (0, 0, item2_1), (0, 0, 0), "A-A", {"from": accounts[1]}
        )


# create new battle
def test_new_roosters_battle_setting_and_stacking(deploy):
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

    tx_data = [(50, 70, 80, 40, 50, 3), accounts[1], {"from": accounts[0]}]
    rooster1 = chicken_nft.mintRooster.call(*tx_data)
    tx = chicken_nft.mintRooster(*tx_data)
    tx.wait(1)

    tx_data = [(51, 66, 78, 42, 55, 3), accounts[1], {"from": accounts[0]}]
    rooster2 = chicken_nft.mintRooster.call(*tx_data)
    tx = chicken_nft.mintRooster(*tx_data)
    tx.wait(1)

    tx_data = [2, 60, 40, 0, 0, 0, accounts[1], {"from": accounts[0]}]
    item1_1 = item_nft.mintItem.call(*tx_data)
    tx = item_nft.mintItem(*tx_data)
    tx.wait(1)

    tx_data = [2, 60, 40, 0, 0, 0, accounts[1], {"from": accounts[0]}]
    item2_1 = item_nft.mintItem.call(*tx_data)
    tx = item_nft.mintItem(*tx_data)
    tx.wait(1)

    tx_data = [rooster1, (0, 0, item1_1), (0, 0, 0), "A-A", {"from": accounts[1]}]
    stake_id1 = battle.stakeRooster.call(*tx_data)
    tx = battle.stakeRooster(*tx_data)
    tx.wait(1)

    tx_data = [rooster2, (0, 0, item2_1), (0, 0, 0), "A-A", {"from": accounts[1]}]
    stake_id2 = battle.stakeRooster.call(*tx_data)
    tx = battle.stakeRooster(*tx_data)
    tx.wait(1)

    tx_data = [stake_id1, stake_id2, {"from": accounts[1]}]
    fight_id = battle.setFight.call(*tx_data)
    tx = battle.setFight(*tx_data)
    tx.wait(1)

    assert fight_id == 2


@pytest.mark.skip_coverage
def test_new_roosters_battle_initiate(deploy):
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
    chain.sleep(600)
    # initiate a fight
    tx = battle.initiateFight(2, {"from": accounts[1]})

    assert tx.events["FightEvent"]["fightData"][2] != 0


# Cancel a fight before initiate
def test_cancel_roosters_fight_before_initiate(deploy):
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

    rhc_token.transfer(accounts[1], 1_000 * 10 ** 18, {"from": accounts[0]})
    rhc_token.approve(vault, 500 * 10 ** 18, {"from": accounts[1]})
    vault.deposit(500 * 10 ** 18, {"from": accounts[1]})

    tx_data = [(50, 70, 80, 40, 50, 3), accounts[1], {"from": accounts[0]}]
    rooster1 = chicken_nft.mintRooster.call(*tx_data)
    tx = chicken_nft.mintRooster(*tx_data)
    tx.wait(1)

    tx_data = [(51, 66, 78, 42, 55, 3), accounts[1], {"from": accounts[0]}]
    rooster2 = chicken_nft.mintRooster.call(*tx_data)
    tx = chicken_nft.mintRooster(*tx_data)
    tx.wait(1)

    tx_data = [2, 60, 40, 0, 0, 0, accounts[1], {"from": accounts[0]}]
    item1_1 = item_nft.mintItem.call(*tx_data)
    tx = item_nft.mintItem(*tx_data)
    tx.wait(1)

    tx_data = [2, 60, 40, 0, 0, 0, accounts[1], {"from": accounts[0]}]
    item2_1 = item_nft.mintItem.call(*tx_data)
    tx = item_nft.mintItem(*tx_data)
    tx.wait(1)

    tx_data = [rooster1, (0, 0, item1_1), (0, 0, 0), "A-A", {"from": accounts[1]}]
    stake_id1 = battle.stakeRooster.call(*tx_data)
    tx = battle.stakeRooster(*tx_data)
    tx.wait(1)

    tx_data = [rooster2, (0, 0, item2_1), (0, 0, 0), "A-A", {"from": accounts[1]}]
    stake_id2 = battle.stakeRooster.call(*tx_data)
    tx = battle.stakeRooster(*tx_data)
    tx.wait(1)

    tx_data = [stake_id1, stake_id2, {"from": accounts[1]}]
    fight_id = battle.setFight.call(*tx_data)
    tx = battle.setFight(*tx_data)
    tx.wait(1)

    chain.sleep(600)
    battle.cancelFight(fight_id, {"from": accounts[1]})

    assert battle.getFightData(fight_id)[0] == 0


# revert cancel a fight before initiate
def test_reverts_cancel_roosters_fight_after_initiate(deploy):
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

    tx_data = [(51, 66, 78, 42, 55, 3), accounts[1], {"from": accounts[0]}]
    rooster2 = chicken_nft.mintRooster.call(*tx_data)
    tx = chicken_nft.mintRooster(*tx_data)
    tx.wait(1)

    tx_data = [2, 60, 40, 0, 0, 0, accounts[1], {"from": accounts[0]}]
    item1_1 = item_nft.mintItem.call(*tx_data)
    tx = item_nft.mintItem(*tx_data)
    tx.wait(1)

    tx_data = [2, 60, 40, 0, 0, 0, accounts[1], {"from": accounts[0]}]
    item2_1 = item_nft.mintItem.call(*tx_data)
    tx = item_nft.mintItem(*tx_data)
    tx.wait(1)

    tx_data = [rooster1, (0, 0, item1_1), (0, 0, 0), "A-A", {"from": accounts[1]}]
    stake_id1 = battle.stakeRooster.call(*tx_data)
    tx = battle.stakeRooster(*tx_data)
    tx.wait(1)

    tx_data = [rooster2, (0, 0, item2_1), (0, 0, 0), "A-A", {"from": accounts[1]}]
    stake_id2 = battle.stakeRooster.call(*tx_data)
    tx = battle.stakeRooster(*tx_data)
    tx.wait(1)

    tx_data = [stake_id1, stake_id2, {"from": accounts[1]}]
    fight_id = battle.setFight.call(*tx_data)
    tx = battle.setFight(*tx_data)
    tx.wait(1)

    chain.sleep(600)
    # initiate a fight
    tx = battle.initiateFight(fight_id, {"from": accounts[1]})

    assert tx.events["FightEvent"]["fightData"][3] != 0
    chain.sleep(600)
    with reverts("Fight is already finished!"):
        battle.cancelFight.call(fight_id, {"from": accounts[1]})


@pytest.mark.skip(reason="Losers burn for now.")
def test_ressurect_from_bones(deploy):
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

    assert vault.getBalance(accounts[1], {"from": accounts[1]}) == 500 * 10 ** 18

    chain = Chain()

    tx_data = [(20, 40, 20, 20, 20, 0), accounts[1], {"from": accounts[0]}]
    rooster1 = chicken_nft.mintRooster.call(*tx_data)
    tx = chicken_nft.mintRooster(*tx_data)
    tx.wait(1)

    tx_data = [(21, 36, 18, 22, 25, 0), accounts[1], {"from": accounts[0]}]
    rooster2 = chicken_nft.mintRooster.call(*tx_data)
    tx = chicken_nft.mintRooster(*tx_data)
    tx.wait(1)

    tx_data = [rooster1, (0, 0, 0), (0, 0, 0), "A-A", {"from": accounts[1]}]
    stake_id1 = battle.stakeRooster.call(*tx_data)
    tx = battle.stakeRooster(*tx_data)
    tx.wait(1)

    tx_data = [rooster2, (0, 0, 0), (0, 0, 0), "A-A", {"from": accounts[1]}]
    stake_id2 = battle.stakeRooster.call(*tx_data)
    tx = battle.stakeRooster(*tx_data)
    tx.wait(1)

    tx_data = [stake_id1, stake_id2, {"from": accounts[1]}]
    fight_id = battle.setFight.call(*tx_data)
    tx = battle.setFight(*tx_data)
    tx.wait(1)

    chain.sleep(600)
    chain.mine(1)

    # initiate a fight
    tx = battle.initiateFight(fight_id, {"from": accounts[1]})
    winnerID = tx.events["FightEvent"]["winnerRoosterId"]
    if winnerID == rooster1:
        looserID = rooster2
    else:
        looserID = rooster1
    chain.sleep(600)

    isRessurected = chicken_nft.ressurectFromBones.call(looserID, {"from": accounts[1]})
    tx = chicken_nft.ressurectFromBones(looserID, {"from": accounts[1]})
    tx.wait(1)

    assert isRessurected == True

    assert vault.getBalance(accounts[1]) == 500 * 10 ** 18

    assert (
        chicken_nft.getStats(looserID, {"from": accounts[1]})[0] == 20
        or chicken_nft.getStats(looserID, {"from": accounts[1]})[0] == 21
    )


@pytest.mark.skip(reason="Losers burn for now.")
def test_reverts_too_late_ressurect_from_bones(deploy):
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
    tx_data = [(20, 40, 20, 20, 20, 0), accounts[1], {"from": accounts[0]}]
    rooster1 = chicken_nft.mintRooster.call(*tx_data)
    tx = chicken_nft.mintRooster(*tx_data)
    tx.wait(1)

    tx_data = [(21, 36, 18, 22, 25, 0), accounts[1], {"from": accounts[0]}]
    rooster2 = chicken_nft.mintRooster.call(*tx_data)
    tx = chicken_nft.mintRooster(*tx_data)
    tx.wait(1)

    tx_data = [rooster1, (0, 0, 0), (0, 0, 0), "A-A", {"from": accounts[1]}]
    stake_id1 = battle.stakeRooster.call(*tx_data)
    tx = battle.stakeRooster(*tx_data)
    tx.wait(1)

    tx_data = [rooster2, (0, 0, 0), (0, 0, 0), "A-A", {"from": accounts[1]}]
    stake_id2 = battle.stakeRooster.call(*tx_data)
    tx = battle.stakeRooster(*tx_data)
    tx.wait(1)

    tx_data = [stake_id1, stake_id2, {"from": accounts[1]}]
    fight_id = battle.setFight.call(*tx_data)
    tx = battle.setFight(*tx_data)
    tx.wait(1)

    chain.sleep(600)
    chain.mine(1)

    # initiate a fight
    tx = battle.initiateFight(fight_id, {"from": accounts[1]})
    chain.sleep(6001)
    if tx.events["FightEvent"]["fightData"][3] == stake_id1:
        with reverts("Too late!"):
            chicken_nft.ressurectFromBones.call(rooster2, {"from": accounts[1]})

    elif tx.events["FightEvent"]["fightData"][3] == stake_id2:
        with reverts("Too late!"):
            chicken_nft.ressurectFromBones.call(rooster1, {"from": accounts[1]})


def test_transfer_ownership_battle(deploy):
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

    battle.transferOwnership(accounts[1], {"from": accounts[0]})


def test_transfer_ownership_battle_zero_address(deploy):
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

    with reverts("Ownable: new owner is the zero address"):
        battle.transferOwnership.call(("0x" + "0" * 40), {"from": accounts[1]})
