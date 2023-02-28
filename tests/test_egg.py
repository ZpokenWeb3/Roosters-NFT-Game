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


# START ==================== TESTS ==========================


# revert if value is lower than mint price
def test_revert_value_not_enough(deploy):
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

    # this tx should fail because value is too small
    with reverts("Payment Error!"):
        egg_nft.mint.call({"from": accounts[1]})


# revert if value is lower than mint many price
def test_revert_value_not_enough_mint_many(deploy):
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

    with reverts("Payment Error!"):
        egg_nft.mintMany.call(int(3), {"from": accounts[1]})


# test mint a basic egg (1-40 quality)
def test_mint_an_egg(deploy):
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

    egg_id = egg_nft.mint.call({"from": accounts[1]})
    tx = egg_nft.mint({"from": accounts[1]})
    tx.wait(1)

    assert 0 < egg_nft.getStats(egg_id)[0] <= 40


# rewert if eggID != 1 create entities in the Chicken_NFT contract from one egg
def test_rewert_creation_entities_in_the_Chicken_NFT_contract_if_eggID(deploy):
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

    with reverts("Egg doesn't belong to sender!"):
        egg_nft.hatchEgg.call(2, {"from": accounts[1]})


# revert on zero ids stake
def test_revert_zero_stake(deploy):
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

    # this tx should fail because zero ids
    with reverts("Rooster doesn't belong to sender!"):
        chicken_nft.stakeHenHouse.call(0, 0, 0, {"from": accounts[1]})


# test change price
def test_change_price(deploy):
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

    newPrice = int(0.02 * 10 ** 18)

    tx = egg_nft.setSettings(0, newPrice, {"from": accounts[0]})
    tx.wait(1)

    rhc_token.transfer(accounts[1], 1_000 * 10 ** 18, {"from": accounts[0]})
    rhc_token.approve(vault, 500 * 10 ** 18, {"from": accounts[1]})
    vault.deposit(500 * 10 ** 18, {"from": accounts[1]})

    egg_id = egg_nft.mint.call({"from": accounts[1]})
    tx = egg_nft.mint({"from": accounts[1]})
    tx.wait(1)

    assert 0 < egg_nft.getStats(egg_id)[0] <= 40


# test generating several basic eggs
def test_many_mint_eggs(deploy):
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

    eggs = egg_nft.mintMany.call(int(3), {"from": accounts[1]})
    tx = egg_nft.mintMany(int(3), {"from": accounts[1]})
    tx.wait(1)

    assert 0 < egg_nft.getStats(eggs[0])[0] <= 40
    assert 0 < egg_nft.getStats(eggs[1])[0] <= 40
    assert 0 < egg_nft.getStats(eggs[2])[0] <= 40


# test Create entities in the Chicken_NFT contract from one egg
def test_creation_entities_in_the_Chicken_NFT_contract_from_one_egg(deploy):
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

    newId = egg_nft.hatchEgg.call(1, {"from": accounts[1]})
    tx = egg_nft.hatchEgg(1, {"from": accounts[1]})
    tx.wait(1)

    print(newId)
    assert newId[1] != 0
    assert len(newId) == 2


# test batch hatching of eggs
def test_batch_hatching_of_eggs(deploy):
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

    eggs = egg_nft.mintMany.call(int(3), {"from": accounts[1]})
    tx = egg_nft.mintMany(int(3), {"from": accounts[1]})
    tx.wait(1)

    new_stuff = egg_nft.hatchMany.call(eggs, {"from": accounts[1]})
    tx = egg_nft.hatchMany(eggs, {"from": accounts[1]})
    tx.wait(1)
    assert 0 <= new_stuff[0][0] < 100
    assert 0 <= new_stuff[0][1] < 100
    assert 0 <= new_stuff[0][2] < 100
    assert 0 < new_stuff[1][0] <= 4
    assert 0 < new_stuff[1][1] <= 4
    assert 0 < new_stuff[1][2] <= 4


# returns address of the chicken NFT owner
def test_get_owner_of_egg_NFT(deploy):
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

    tx = egg_nft.ownerOf(2, {"from": accounts[1]})

    assert tx == accounts[1]


# test balance of egg_nft
def test_balance_of_egg_nft(deploy):
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
    balances = egg_nft.balanceOf(accounts[0], 1, {"from": accounts[0]})
    assert balances == 0


# test balance of chicken nft
def test_revert_balance_of_egg_nft(deploy):
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
    with reverts("ERC1155: balance query for the zero address"):
        egg_nft.balanceOf.call(("0x" + "0" * 40), 1, {"from": accounts[0]})


# test balance of batch chicken nft
def test_balance_of_batch_egg_nft(deploy):
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
    return_data = egg_nft.balanceOfBatch([accounts[0]], [1], {"from": accounts[0]})
    assert return_data == (0,)


# set approval for all
def test_revert_set_approval_for_all_egg_contract(deploy):
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

    with reverts("ERC1155: setting approval status for self"):
        egg_nft.setApprovalForAll.call(accounts[0], True, {"from": accounts[0]})


# set approval for all
def test_set_approval_for_all_egg_contract_false(deploy):
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

    egg_nft.setApprovalForAll(accounts[1], False, {"from": accounts[0]})


# set approval for all
def test_set_approval_for_all_egg_contract_true(deploy):
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

    egg_nft.setApprovalForAll(accounts[1], True, {"from": accounts[0]})


# is approval for all
def test_check_approval_for_all_egg_contract_False(deploy):
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

    data = egg_nft.isApprovedForAll(accounts[0], accounts[0], {"from": accounts[0]})
    assert data == False


# is approval for all
def test_check_approval_for_all_egg_contract_True(deploy):
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

    data = egg_nft.isApprovedForAll(accounts[0], accounts[1], {"from": accounts[0]})
    assert data == True


# set URL for egg
def test_set_URL_egg(deploy):
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

    egg_nft.setURI("testURL", {"from": accounts[0]})


# testing ownable
def test_transfer_ownership_egg(deploy):
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

    egg_nft.transferOwnership(accounts[1], {"from": accounts[0]})


# testing ownable zero address
def test_transfer_ownership_egg_zero_address(deploy):
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
        egg_nft.transferOwnership.call(("0x" + "0" * 40), {"from": accounts[1]})
