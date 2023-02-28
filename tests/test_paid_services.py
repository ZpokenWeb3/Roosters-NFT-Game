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
def test_paid_deposit_token(deploy):
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


def test_paid_pay_for_eggs(deploy):
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

    tx = egg_nft.setSettings(0, 50, {"from": accounts[0]})

    ids = egg_nft.mintMany.call(2, {"from": accounts[1]})
    tx = egg_nft.mintMany(2, {"from": accounts[1]})
    tx.wait(1)

    assert ids == (1, 2)
    assert vault.getBalance(accounts[1], {"from": accounts[1]}) == 900


def test_paid_pay_cancel_fight(deploy):
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
    assert vault.getBalance(accounts[1], {"from": accounts[1]}) == 900

    # Set Cancel Price
    battle.setSettings(0, 0, 0, 0, 50, 0, 0, {"from": accounts[0]})

    tx_data = [(70, 80, 90, 50, 60, 5), accounts[1], {"from": accounts[0]}]
    rooster1 = chicken_nft.mintRooster.call(*tx_data)
    tx = chicken_nft.mintRooster(*tx_data)
    tx.wait(1)

    tx_data = [(71, 76, 88, 52, 65, 5), accounts[1], {"from": accounts[0]}]
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

    fight_id = battle.setFight.call(stake_id1, stake_id2, {"from": accounts[1]})
    tx = battle.setFight(stake_id1, stake_id2, {"from": accounts[1]})
    tx.wait(1)

    battle.cancelFight.call(fight_id, {"from": accounts[1]})
    battle.cancelFight(fight_id, {"from": accounts[1]})
    assert vault.getBalance(accounts[1], {"from": accounts[1]}) == 850


@pytest.mark.skip(reason="Losers burn for now.")
def test_paid_pay_for_ressurection(deploy):
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

    chicken_nft.setSettings(0, 0, 0, 0, 0, 0, 0, 0, 0, 50, {"from": accounts[0]})

    chain = Chain()
    rooster1 = chicken_nft.mintRooster.call(
        (20, 40, 20, 20, 20, 0), accounts[1], {"from": accounts[0]}
    )
    tx = chicken_nft.mintRooster(
        (20, 40, 20, 20, 20, 0), accounts[1], {"from": accounts[0]}
    )

    rooster2 = chicken_nft.mintRooster.call(
        (21, 36, 18, 22, 25, 0), accounts[1], {"from": accounts[0]}
    )
    tx = chicken_nft.mintRooster(
        (21, 36, 18, 22, 25, 0), accounts[1], {"from": accounts[0]}
    )

    stake_id1 = battle.stakeRooster.call(
        rooster1, (0, 0, 0), (0, 0, 0), "A-A", {"from": accounts[1]}
    )
    tx = battle.stakeRooster(
        rooster1, (0, 0, 0), (0, 0, 0), "A-A", {"from": accounts[1]}
    )
    tx.wait(1)

    stake_id2 = battle.stakeRooster.call(
        rooster2, (0, 0, 0), (0, 0, 0), "A-A", {"from": accounts[1]}
    )
    tx = battle.stakeRooster(
        rooster2, (0, 0, 0), (0, 0, 0), "A-A", {"from": accounts[1]}
    )
    tx.wait(1)

    fight_id = battle.setFight.call(stake_id1, stake_id2, {"from": accounts[1]})
    tx = battle.setFight(stake_id1, stake_id2, {"from": accounts[1]})
    tx.wait(1)

    chain.sleep(600)
    # initiate a fight
    tx = battle.initiateFight(fight_id, {"from": accounts[1]})
    chain.sleep(1200)

    if tx.events["FightEvent"]["fightData"][4] == 3:
        isRessurected = chicken_nft.ressurectFromBones.call(3, {"from": accounts[1]})
        tx = chicken_nft.ressurectFromBones(3, {"from": accounts[1]})
        tx.wait(1)
        assert isRessurected == True

    elif tx.events["FightEvent"]["fightData"][4] == 4:
        isRessurected = chicken_nft.ressurectFromBones.call(4, {"from": accounts[1]})
        tx = chicken_nft.ressurectFromBones(4, {"from": accounts[1]})
        tx.wait(1)
        assert isRessurected == True

    assert vault.getBalance(accounts[1]) == 800


def test_paid_betting_payment(deploy):
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
    tx_data = [(70, 80, 90, 50, 60, 5), accounts[1], {"from": accounts[0]}]
    rooster1 = chicken_nft.mintRooster.call(*tx_data)
    tx = chicken_nft.mintRooster(*tx_data)
    tx.wait(1)

    tx_data = [(71, 76, 88, 52, 65, 5), accounts[1], {"from": accounts[0]}]
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

    fight_id = battle.setFight.call(stake_id1, stake_id2, {"from": accounts[1]})
    tx = battle.setFight(stake_id1, stake_id2, {"from": accounts[1]})
    tx.wait(1)

    # Give some tokens
    rhc_token.transfer(accounts[0], 1_000 * 10 ** 18, {"from": accounts[0]})
    rhc_token.transfer(accounts[1], 1_000 * 10 ** 18, {"from": accounts[0]})
    rhc_token.transfer(accounts[2], 1_000 * 10 ** 18, {"from": accounts[0]})

    # Approve token
    rhc_token.approve(vault, 500 * 10 ** 18, {"from": accounts[0]})
    rhc_token.approve(vault, 500 * 10 ** 18, {"from": accounts[1]})
    rhc_token.approve(vault, 500 * 10 ** 18, {"from": accounts[2]})

    # Deposit token
    vault.deposit(500, {"from": accounts[0]})
    vault.deposit(500, {"from": accounts[1]})
    vault.deposit(500, {"from": accounts[2]})

    assert vault.getBalance(accounts[0]) == 650
    assert vault.getBalance(accounts[1]) == 1350
    assert vault.getBalance(accounts[2]) == 500
    # Make bets
    tx = bets.betOnFight(fight_id, stake_id1, 400, {"from": accounts[0]})
    tx = bets.betOnFight(fight_id, stake_id2, 400, {"from": accounts[1]})
    tx = bets.betOnFight(fight_id, stake_id2, 400, {"from": accounts[2]})
    tx.wait(1)

    # wait 10 minutes
    chain.sleep(600)
    # initiate a fight
    tx = battle.initiateFight(fight_id, {"from": accounts[1]})
    tx.wait(1)
    # wait 20 minutes
    chain.sleep(1200)
    assert vault.getBalance(accounts[0]) == 250 or vault.getBalance(accounts[0]) == 1050
    assert vault.getBalance(accounts[1]) == 950 or vault.getBalance(accounts[1]) == 1750
    assert vault.getBalance(accounts[2]) == 100 or vault.getBalance(accounts[2]) == 900

    if bets.checkReward(fight_id, accounts[0]) > 0:
        tx = bets.claimReward(fight_id, {"from": accounts[0]})
        assert vault.getBalance(accounts[0], {"from": accounts[0]}) == 1450
    if bets.checkReward(fight_id, accounts[1]) > 0:
        tx = bets.claimReward(fight_id, {"from": accounts[1]})
        assert vault.getBalance(accounts[1], {"from": accounts[1]}) == 1544
    if bets.checkReward(fight_id, accounts[2]) > 0:
        tx = bets.claimReward(fight_id, {"from": accounts[2]})
        assert vault.getBalance(accounts[2], {"from": accounts[2]}) == 694
    tx.wait(1)

    assert tx.events["ClaimReward"]["userAddress"] != ("0x" + "0" * 40)
    # commission is 1%
    assert (
        tx.events["ClaimReward"]["rewardAmount"] == 1188
        or tx.events["ClaimReward"]["rewardAmount"] == 594
    )
