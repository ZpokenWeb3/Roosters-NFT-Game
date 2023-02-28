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

# test betting
def test_mint_roosters_and_set_fight(deploy):
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

    tx_data = [(50, 70, 80, 40, 50, 0), accounts[0], {"from": accounts[0]}]
    rooster1 = chicken_nft.mintRooster.call(*tx_data)
    tx = chicken_nft.mintRooster(*tx_data)
    tx.wait(1)

    tx_data = [(51, 66, 78, 42, 55, 1), accounts[0], {"from": accounts[0]}]
    rooster2 = chicken_nft.mintRooster.call(*tx_data)
    tx = chicken_nft.mintRooster(*tx_data)
    tx.wait(1)

    # stake roosters
    tx_data = [rooster1, (0, 0, 0), (0, 0, 0), "A-A", {"from": accounts[0]}]
    stake_id1 = battle.stakeRooster.call(*tx_data)
    tx = battle.stakeRooster(*tx_data)
    tx.wait(1)

    tx_data = [rooster2, (0, 0, 0), (0, 0, 0), "A-A", {"from": accounts[0]}]
    stake_id2 = battle.stakeRooster.call(*tx_data)
    tx = battle.stakeRooster(*tx_data)
    tx.wait(1)

    # Setting a fight
    tx_data = [stake_id1, stake_id2, {"from": accounts[0]}]
    fight_id = battle.setFight.call(*tx_data)
    tx = battle.setFight(*tx_data)
    tx.wait(1)
    assert fight_id == 1

    # Give some tokens
    rhc_token.transfer(accounts[0], 1_000 * 10 ** 18, {"from": accounts[0]})
    rhc_token.transfer(accounts[1], 1_000 * 10 ** 18, {"from": accounts[0]})
    rhc_token.transfer(accounts[2], 1_000 * 10 ** 18, {"from": accounts[0]})

    # Approve token
    rhc_token.approve(vault, 500 * 10 ** 18, {"from": accounts[0]})
    rhc_token.approve(vault, 500 * 10 ** 18, {"from": accounts[1]})
    rhc_token.approve(vault, 500 * 10 ** 18, {"from": accounts[2]})

    # Deposit token
    vault.deposit(500 * 10 ** 18, {"from": accounts[0]})
    vault.deposit(500 * 10 ** 18, {"from": accounts[1]})
    vault.deposit(500 * 10 ** 18, {"from": accounts[2]})

    # Make bets
    tx = bets.betOnFight(fight_id, stake_id1, 100_000000, {"from": accounts[0]})
    tx = bets.betOnFight(fight_id, stake_id2, 50_000000, {"from": accounts[1]})
    tx = bets.betOnFight(fight_id, stake_id2, 50_000000, {"from": accounts[2]})
    tx.wait(1)


def test_initiate_battle_with_betting(deploy):
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
    fight_id = 1
    chain = Chain()
    # wait 10 minutes
    chain.sleep(600)
    # initiate a fight
    tx = battle.initiateFight(fight_id, {"from": accounts[0]})
    tx.wait(1)


def test_check_and_claim_reward(deploy):
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
    fight_id = 1
    chain = Chain()
    # wait 10 minutes
    chain.sleep(1200)
    if bets.checkReward(fight_id, accounts[0]) > 0:
        tx = bets.claimReward(fight_id, {"from": accounts[0]})
    if bets.checkReward(fight_id, accounts[1]) > 0:
        tx = bets.claimReward(fight_id, {"from": accounts[1]})
    if bets.checkReward(fight_id, accounts[2]) > 0:
        tx = bets.claimReward(fight_id, {"from": accounts[2]})

    tx.wait(1)

    assert tx.events["ClaimReward"]["userAddress"] != ("0x" + "0" * 40)
    # commission is 1%
    assert tx.events["ClaimReward"]["rewardAmount"] >= 99_000000


# test revert betting, because of finished fight already
@pytest.mark.skip_coverage
def test_reverts_bet_on_Fight(deploy):
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
    vault.deposit(500 * 10 ** 18, {"from": accounts[1]})
    with reverts("Fight is finished!"):
        bets.betOnFight.call(1, 1, 50_000000, {"from": accounts[1]})


# test revert betting on roosters battle because of "Fight is not finished!"
def test_revert_betting_fight_is_not_finished(deploy):
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

    tx_data = [(50, 70, 80, 40, 50, 0), accounts[0], {"from": accounts[0]}]
    rooster1 = chicken_nft.mintRooster.call(*tx_data)
    tx = chicken_nft.mintRooster(*tx_data)
    tx.wait(1)

    tx_data = [(51, 66, 78, 42, 55, 1), accounts[0], {"from": accounts[0]}]
    rooster2 = chicken_nft.mintRooster.call(*tx_data)
    tx = chicken_nft.mintRooster(*tx_data)
    tx.wait(1)

    # stake roosters
    tx_data = [rooster1, (0, 0, 0), (0, 0, 0), "A-A", {"from": accounts[0]}]
    stake_id1 = battle.stakeRooster.call(*tx_data)
    tx = battle.stakeRooster(*tx_data)
    tx.wait(1)

    tx_data = [rooster2, (0, 0, 0), (0, 0, 0), "A-A", {"from": accounts[0]}]
    stake_id2 = battle.stakeRooster.call(*tx_data)
    tx = battle.stakeRooster(*tx_data)
    tx.wait(1)

    # Setting a fight
    tx_data = [stake_id1, stake_id2, {"from": accounts[0]}]
    fight_id = battle.setFight.call(*tx_data)
    tx = battle.setFight(*tx_data)
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
    vault.deposit(500 * 10 ** 18, {"from": accounts[0]})
    vault.deposit(500 * 10 ** 18, {"from": accounts[1]})
    vault.deposit(500 * 10 ** 18, {"from": accounts[2]})

    # Make bets
    tx = bets.betOnFight(fight_id, stake_id1, 100_000000, {"from": accounts[0]})
    tx = bets.betOnFight(fight_id, stake_id2, 50_000000, {"from": accounts[1]})
    tx = bets.betOnFight(fight_id, stake_id2, 50_000000, {"from": accounts[2]})
    tx.wait(1)

    if bets.checkReward(fight_id, accounts[0]) > 0:
        with reverts("Fight is not finished!"):
            bets.claimReward.call(fight_id, {"from": accounts[0]})


# Return bet for a canceled fight
def test_return_canceled_fight_bet(deploy):
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

    tx_data = [(50, 70, 80, 40, 50, 0), accounts[0], {"from": accounts[0]}]
    rooster1 = chicken_nft.mintRooster.call(*tx_data)
    tx = chicken_nft.mintRooster(*tx_data)
    tx.wait(1)

    tx_data = [(51, 66, 78, 42, 55, 1), accounts[0], {"from": accounts[0]}]
    rooster2 = chicken_nft.mintRooster.call(*tx_data)
    tx = chicken_nft.mintRooster(*tx_data)
    tx.wait(1)

    # stake roosters
    tx_data = [rooster1, (0, 0, 0), (0, 0, 0), "A-A", {"from": accounts[0]}]
    stake_id1 = battle.stakeRooster.call(*tx_data)
    tx = battle.stakeRooster(*tx_data)
    tx.wait(1)

    tx_data = [rooster2, (0, 0, 0), (0, 0, 0), "A-A", {"from": accounts[0]}]
    stake_id2 = battle.stakeRooster.call(*tx_data)
    tx = battle.stakeRooster(*tx_data)
    tx.wait(1)

    # Setting a fight
    tx_data = [stake_id1, stake_id2, {"from": accounts[0]}]
    fight_id = battle.setFight.call(*tx_data)
    tx = battle.setFight(*tx_data)
    tx.wait(1)

    chain.sleep(600)
    chain.mine(1)

    # Give some tokens
    rhc_token.transfer(accounts[0], 1_000 * 10 ** 18, {"from": accounts[0]})
    rhc_token.transfer(accounts[1], 1_000 * 10 ** 18, {"from": accounts[0]})
    rhc_token.transfer(accounts[2], 1_000 * 10 ** 18, {"from": accounts[0]})

    # Approve token
    rhc_token.approve(vault, 500 * 10 ** 18, {"from": accounts[0]})
    rhc_token.approve(vault, 500 * 10 ** 18, {"from": accounts[1]})
    rhc_token.approve(vault, 500 * 10 ** 18, {"from": accounts[2]})

    # Deposit token
    vault.deposit(500 * 10 ** 18, {"from": accounts[0]})
    vault.deposit(500 * 10 ** 18, {"from": accounts[1]})
    vault.deposit(500 * 10 ** 18, {"from": accounts[2]})

    # Make bets
    tx = bets.betOnFight(fight_id, stake_id1, 20_000000, {"from": accounts[0]})
    tx = bets.betOnFight(fight_id, stake_id2, 100_000000, {"from": accounts[1]})
    tx = bets.betOnFight(fight_id, stake_id2, 70_000000, {"from": accounts[2]})
    tx.wait(1)

    battle.cancelFight(fight_id, {"from": accounts[0]})
    tx = bets.returnCanceledFightBet(fight_id, {"from": accounts[1]})
    assert tx.events["ReturnBet"]["fightId"] == fight_id
    assert tx.events["ReturnBet"]["returnAmount"] == 100_000000

    tx = bets.returnCanceledFightBet(fight_id, {"from": accounts[0]})
    assert tx.events["ReturnBet"]["fightId"] == fight_id
    assert tx.events["ReturnBet"]["returnAmount"] == 20_000000

    tx = bets.returnCanceledFightBet(fight_id, {"from": accounts[2]})
    assert tx.events["ReturnBet"]["fightId"] == fight_id
    assert tx.events["ReturnBet"]["returnAmount"] == 70_000000


# test revert bets too much
def test_revert_bets_too_much(deploy):
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

    tx_data = [(50, 70, 80, 40, 50, 0), accounts[0], {"from": accounts[0]}]
    rooster1 = chicken_nft.mintRooster.call(*tx_data)
    tx = chicken_nft.mintRooster(*tx_data)
    tx.wait(1)

    tx_data = [(51, 66, 78, 42, 55, 1), accounts[0], {"from": accounts[0]}]
    rooster2 = chicken_nft.mintRooster.call(*tx_data)
    tx = chicken_nft.mintRooster(*tx_data)
    tx.wait(1)

    # stake roosters
    tx_data = [rooster1, (0, 0, 0), (0, 0, 0), "A-A", {"from": accounts[0]}]
    stake_id1 = battle.stakeRooster.call(*tx_data)
    tx = battle.stakeRooster(*tx_data)
    tx.wait(1)

    tx_data = [rooster2, (0, 0, 0), (0, 0, 0), "A-A", {"from": accounts[0]}]
    stake_id2 = battle.stakeRooster.call(*tx_data)
    tx = battle.stakeRooster(*tx_data)
    tx.wait(1)

    # Setting a fight
    tx_data = [stake_id1, stake_id2, {"from": accounts[0]}]
    fight_id = battle.setFight.call(*tx_data)
    tx = battle.setFight(*tx_data)
    tx.wait(1)

    rhc_token.transfer(accounts[1], 1_000 * 10 ** 18, {"from": accounts[0]})
    rhc_token.approve(vault, 500 * 10 ** 18, {"from": accounts[1]})
    vault.deposit(500 * 10 ** 18, {"from": accounts[1]})

    # Make bets
    with reverts("Payment Error!"):
        bets.betOnFight.call(
            fight_id, stake_id1, 1_500_000_000 * 10 ** 18, {"from": accounts[0]}
        )


def test_transfer_ownership_bets_zero_address(deploy):
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
        bets.transferOwnership.call(("0x" + "0" * 40), {"from": accounts[0]})


def test_transfer_ownership_bets(deploy):
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

    bets.transferOwnership(accounts[1], {"from": accounts[0]})
