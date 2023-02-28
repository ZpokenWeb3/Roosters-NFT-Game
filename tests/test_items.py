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

# Get stake status of rooster or hen
def test_get_stake_status_of_item(deploy):
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

    tx = item_nft.isStaked(1, {"from": accounts[1]})

    assert tx == False


# returns address of the chicken NFT owner
def test_get_owner_of_item_NFT(deploy):
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

    item1_1 = item_nft.mintItem.call(
        2, 50, 20, 0, 0, 0, accounts[1], {"from": accounts[0]}
    )
    tx = item_nft.mintItem(2, 50, 20, 0, 0, 0, accounts[1], {"from": accounts[0]})
    tx.wait(1)
    tx = item_nft.ownerOf(item1_1, {"from": accounts[1]})

    assert tx == accounts[1]


# set URL for item
def test_set_URL_item(deploy):
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

    item_nft.setURI("testURL", {"from": accounts[0]})


# get item stats
def test_get_item_status(deploy):
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

    tx = item_nft.getStats(1, {"from": accounts[1]})

    assert tx[0] >= 0
    assert tx[1] >= 0
    assert tx[2] >= 0
    assert tx[3] >= 0
    assert tx[4] >= 0


# get item stats
def test_get_item_status_another_item(deploy):
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

    tx = item_nft.getStats(2, {"from": accounts[1]})

    assert tx[0] >= 0
    assert tx[1] >= 0
    assert tx[2] >= 0
    assert tx[3] >= 0
    assert tx[4] >= 0


# get item stats
def test_get_item_status_another_item3(deploy):
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

    tx = item_nft.getStats(3, {"from": accounts[1]})

    assert tx[0] >= 0
    assert tx[1] >= 0
    assert tx[2] >= 0
    assert tx[3] >= 0
    assert tx[4] >= 0


# get item stats
def test_get_item_status_another_item3(deploy):
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

    tx = item_nft.getStats(4, {"from": accounts[1]})

    assert tx[0] >= 0
    assert tx[1] >= 0
    assert tx[2] >= 0
    assert tx[3] >= 0
    assert tx[4] >= 0


# testing ankh ressurection item NFT burning if rooster lose
def test_ankh_ressurection_item_nft(deploy):
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
        (50, 70, 80, 40, 50, 0), accounts[1], {"from": accounts[0]}
    )
    tx = chicken_nft.mintRooster(
        (50, 70, 80, 40, 50, 0), accounts[1], {"from": accounts[0]}
    )
    tx.wait(1)

    rooster2 = chicken_nft.mintRooster.call(
        (53, 70, 80, 40, 50, 0), accounts[1], {"from": accounts[0]}
    )
    tx = chicken_nft.mintRooster(
        (53, 70, 80, 40, 50, 0), accounts[1], {"from": accounts[0]}
    )
    tx.wait(1)

    # Mint Items
    # _type, _selector,  _eggQuality, _zodiac, _vampiric, account
    # Ankh ressurection item
    item1_1 = item_nft.mintItem.call(
        2, 4, 0, 0, 0, 0, accounts[1], {"from": accounts[0]}
    )
    tx = item_nft.mintItem(2, 4, 0, 0, 0, 0, accounts[1], {"from": accounts[0]})
    tx.wait(1)
    # Item 2 - Ankh ressurection item
    item2_1 = item_nft.mintItem.call(
        2, 4, 0, 0, 0, 0, accounts[1], {"from": accounts[0]}
    )
    tx = item_nft.mintItem(2, 4, 0, 0, 0, 0, accounts[1], {"from": accounts[0]})
    tx.wait(1)

    # stake roosters
    stake_id1 = battle.stakeRooster.call(
        rooster1, (0, 0, item1_1), (0, 0, 0), "A-A", {"from": accounts[1]}
    )
    tx = battle.stakeRooster(
        rooster1, (0, 0, item1_1), (0, 0, 0), "A-A", {"from": accounts[1]}
    )
    tx.wait(1)

    stake_id2 = battle.stakeRooster.call(
        rooster2, (0, 0, item2_1), (0, 0, 0), "A-A", {"from": accounts[1]}
    )
    tx = battle.stakeRooster(
        rooster2, (0, 0, item2_1), (0, 0, 0), "A-A", {"from": accounts[1]}
    )
    tx.wait(1)

    # setting a fight
    fight_id = battle.setFight.call(stake_id1, stake_id2, {"from": accounts[1]})
    tx = battle.setFight(stake_id1, stake_id2, {"from": accounts[1]})
    tx.wait(1)

    # wait 10 minutes
    chain.sleep(600)

    # initiate a fight
    results = battle.initiateFight.call(fight_id, {"from": accounts[0]})
    tx = battle.initiateFight(fight_id, {"from": accounts[0]})
    tx.wait(1)

    assert item_nft.getStats(item1_1, {"from": accounts[1]}) == (
        0,
        0,
        0,
        0,
        0,
        0,
    ) or item_nft.getStats(item2_1, {"from": accounts[1]}) == (
        0,
        0,
        0,
        0,
        0,
        0,
    )


# testing win requirements items for roosters
def test_revert_rooster_doesnt_have_enough_wins(deploy):
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
        (50, 70, 80, 40, 50, 0), accounts[0], {"from": accounts[0]}
    )
    tx = chicken_nft.mintRooster(
        (50, 70, 80, 40, 50, 0), accounts[0], {"from": accounts[0]}
    )
    tx.wait(1)

    # Item 2 - HP +25%
    item2_1 = item_nft.mintItem.call(
        2, 97, 30, 0, 3, 0, accounts[0], {"from": accounts[0]}
    )
    tx = item_nft.mintItem(2, 97, 30, 0, 3, 0, accounts[0], {"from": accounts[0]})
    tx.wait(1)

    with reverts("Rooster doesn't have enough wins for this Item!"):
        battle.stakeRooster.call(
            rooster1, (0, 0, item2_1), (0, 0, 0), "A-A", {"from": accounts[0]}
        )


# test balance of item_nft
def test_balance_of_item_nft(deploy):
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
    balances = item_nft.balanceOf(accounts[1], 1, {"from": accounts[1]})
    assert balances == 1


# test balance of itemnft
def test_revert_balance_of_item_nft(deploy):
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
        item_nft.balanceOf.call(("0x" + "0" * 40), 1, {"from": accounts[0]})


# test balance of batch item nft
def test_balance_of_batch_item_nft(deploy):
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
    return_data = item_nft.balanceOfBatch([accounts[1]], [1], {"from": accounts[1]})
    assert return_data == (1,)


# set approval for all
def test_revert_set_approval_for_all_item_contract(deploy):
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
        item_nft.setApprovalForAll.call(accounts[0], True, {"from": accounts[0]})


# set approval for all
def test_set_approval_for_all_item_contract_false(deploy):
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

    item_nft.setApprovalForAll(accounts[1], False, {"from": accounts[0]})


# set approval for all
def test_set_approval_for_all_item_contract_true(deploy):
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

    item_nft.setApprovalForAll(accounts[1], True, {"from": accounts[0]})


# is approval for all
def test_check_approval_for_all_item_contract_False(deploy):
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

    data = item_nft.isApprovedForAll(accounts[0], accounts[0], {"from": accounts[0]})
    assert data == False


# is approval for all
def test_check_approval_for_all_item_contract_True(deploy):
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

    data = item_nft.isApprovedForAll(accounts[0], accounts[1], {"from": accounts[0]})
    assert data == True


# safeTransferFrom
def test_save_transfer_item_contract_from(deploy):
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

    balanceBefore = item_nft.balanceOf(accounts[2], 1, {"from": accounts[1]})
    assert balanceBefore == 0

    item_nft.safeTransferFrom(
        accounts[1], accounts[2], 1, (1), 1, {"from": accounts[1]}
    )
    balanceAfter = item_nft.balanceOf(accounts[2], 1, {"from": accounts[1]})
    assert balanceAfter == 1


def test_transfer_ownership_item_zero_address(deploy):
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
        item_nft.transferOwnership.call(("0x" + "0" * 40), {"from": accounts[0]})


def test_transfer_ownership_item(deploy):
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

    item_nft.transferOwnership(accounts[1], {"from": accounts[0]})
