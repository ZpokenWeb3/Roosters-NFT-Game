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


# ////////////////////////////////////////////// ERC20 ///////////////////////////////////////////
# testing erc 20
def test_erc20_mint(deploy):
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

    rhc_token.burn(10000, {"from": accounts[0]})


def test_reverts_rhc_token_burn(deploy):
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
    with reverts(""):
        rhc_token.burn.call(1_500_000_000 * 10 ** 18, {"from": accounts[1]})


def test_get_balance(deploy):
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

    balance = vault.getBalance(accounts[1], {"from": accounts[1]})
    assert balance == 500 * 10 ** 18


def test_withdraw_revert_not_enough_balance(deploy):
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

    with reverts("Not enough balance!"):
        vault.withdraw.call(1_500_000_000 * 10 ** 18, {"from": accounts[1]})


def test_withdraw(deploy):
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

    vault.withdraw(500 * 10 ** 18, {"from": accounts[1]})


# END   ==================== TESTS ==========================
