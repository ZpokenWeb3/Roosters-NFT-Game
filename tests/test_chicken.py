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

# check chicken status
def test_check_chicken_status(deploy):
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

    eggs = egg_nft.mintMany.call(int(10), {"from": accounts[1]})
    tx = egg_nft.mintMany(int(10), {"from": accounts[1]})
    tx.wait(1)

    assert eggs == (1, 2, 3, 4, 5, 6, 7, 8, 9, 10)

    tx = egg_nft.hatchMany(eggs, {"from": accounts[1]})
    tx.wait(1)

    assert chicken_nft.getStats(1)[0] >= 0


def test_check_status(deploy):
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

    tx = chicken_nft.getStats(2, {"from": accounts[1]})

    assert tx[0] > 0


# Update Hen House and generate eggs as many as cycles passed
def test_revert_update_hen_house_and_generate_eggs(deploy):
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

    with reverts("Hen House is empty!"):
        chicken_nft.updateHenHouse.call(1, {"from": accounts[1]})


# Open staked hen house and generate eggs as many as cycles passed
def test_open_staked_hen_house_and_generate_eggs(deploy):
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

    with reverts("Hen House is empty!"):
        chicken_nft.releaseHenHouse.call(1, {"from": accounts[1]})


# Stake a rooster witout han
def test_Stake_a_hen_doesnt_belong_to_sender(deploy):
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

    rooster = chicken_nft.mintRooster.call(
        (31, 31, 31, 31, 31, 0), accounts[1], {"from": accounts[0]}
    )
    tx = chicken_nft.mintRooster(
        (31, 31, 31, 31, 31, 0), accounts[1], {"from": accounts[0]}
    )
    tx.wait(1)

    with reverts("Hen doesn't belong to sender!"):
        chicken_nft.stakeHenHouse.call(rooster, 0, 0, {"from": accounts[1]})


# Stake a han witout rooster
def test_Stake_a_rooster_doesnt_belong_to_sender(deploy):
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

    with reverts("Rooster doesn't belong to sender!"):
        chicken_nft.stakeHenHouse.call(0, 1, 0, {"from": accounts[1]})


# Stake a rooster and a han
def test_Stake_a_rooster_and_a_han(deploy):
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

    afterStake = chicken_nft.stakeHenHouse.call(1, 1, 0, {"from": accounts[1]})
    tx = chicken_nft.stakeHenHouse(1, 1, 0, {"from": accounts[1]})
    tx.wait(1)

    assert afterStake == 1


# Stake a hen and a han
def test_Stake_a_rooster_already_staked(deploy):
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

    with reverts("Rooster is staked already!"):
        chicken_nft.stakeHenHouse.call(1, 1, 0, {"from": accounts[1]})


# rewert stake a hen already staked
def test_rewert_Stake_a_hen_already_staked(deploy):
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

    rooster = chicken_nft.mintRooster.call(
        (31, 31, 31, 31, 31, 0), accounts[1], {"from": accounts[0]}
    )
    tx = chicken_nft.mintRooster(
        (31, 31, 31, 31, 31, 0), accounts[1], {"from": accounts[0]}
    )
    tx.wait(1)

    with reverts("Hen is staked already!"):
        chicken_nft.stakeHenHouse.call(rooster, 1, 0, {"from": accounts[1]})


# rewert stake Item doesn't belong to sender
def test_rewert_Stake_item_doesnt_belong_to_sender(deploy):
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

    rooster = chicken_nft.mintRooster.call(
        (31, 31, 31, 31, 31, 0), accounts[1], {"from": accounts[0]}
    )
    tx = chicken_nft.mintRooster(
        (31, 31, 31, 31, 31, 0), accounts[1], {"from": accounts[0]}
    )
    tx.wait(1)

    item1_1 = item_nft.mintItem.call(
        3, 50, 20, 0, 0, 0, accounts[2], {"from": accounts[0]}
    )
    tx = item_nft.mintItem(3, 50, 20, 0, 0, 0, accounts[2], {"from": accounts[0]})
    tx.wait(1)

    with reverts("Item doesn't belong to sender!"):
        chicken_nft.stakeHenHouse.call(rooster, 2, item1_1, {"from": accounts[1]})


# rewert stake test "Not a female item"
def test_not_female_item(deploy):
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

    rooster = chicken_nft.mintRooster.call(
        (31, 31, 31, 31, 31, 0), accounts[1], {"from": accounts[0]}
    )
    tx = chicken_nft.mintRooster(
        (31, 31, 31, 31, 31, 0), accounts[1], {"from": accounts[0]}
    )
    tx.wait(1)

    item = item_nft.mintItem.call(
        1, 83, 98, 0, 0, 0, accounts[1], {"from": accounts[0]}
    )
    tx = item_nft.mintItem(1, 83, 98, 0, 0, 0, accounts[1], {"from": accounts[0]})
    tx.wait(1)

    with reverts("Not a female item!"):
        chicken_nft.stakeHenHouse.call(rooster, 3, item, {"from": accounts[1]})


# Stake a rooster and a han with item
def test_Stake_a_rooster_and_a_hen_with_item(deploy):
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

    item = item_nft.mintItem.call(
        3, 83, 98, 0, 0, 0, accounts[1], {"from": accounts[0]}
    )
    tx = item_nft.mintItem(3, 83, 98, 0, 0, 0, accounts[1], {"from": accounts[0]})
    tx.wait(1)

    afterStake = chicken_nft.stakeHenHouse.call(2, 2, item, {"from": accounts[1]})
    tx = chicken_nft.stakeHenHouse(2, 2, item, {"from": accounts[1]})
    tx.wait(1)

    assert afterStake == 2


# Stake a rooster and a han with item
def test_Stake_a_rooster_and_a_hen_with_item2(deploy):
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

    rooster = chicken_nft.mintRooster.call(
        (31, 31, 31, 31, 31, 0), accounts[1], {"from": accounts[0]}
    )
    tx = chicken_nft.mintRooster(
        (31, 31, 31, 31, 31, 0), accounts[1], {"from": accounts[0]}
    )
    tx.wait(1)

    item = item_nft.mintItem.call(
        3, 83, 98, 0, 0, 0, accounts[1], {"from": accounts[0]}
    )
    tx = item_nft.mintItem(3, 83, 98, 0, 0, 0, accounts[1], {"from": accounts[0]})
    tx.wait(1)

    afterStake = chicken_nft.stakeHenHouse.call(rooster, 3, item, {"from": accounts[1]})
    tx = chicken_nft.stakeHenHouse(rooster, 3, item, {"from": accounts[1]})
    tx.wait(1)

    assert afterStake == 3


# Get number of cycles passed for the staking
def test_get_number_of_cycles_passed_for_the_staking(deploy):
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

    tx = chicken_nft.checkStakeCycle(1, {"from": accounts[1]})
    check = tx

    assert tx == 0


# revert update Hen House and generate eggs as many as cycles passed
def test_reverts_update_hen_house_and_generate_eggs(deploy):
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

    with reverts("Hen House did not complete a cycle!"):
        chicken_nft.updateHenHouse.call(1, {"from": accounts[1]})


# Open staked hen house and generate eggs as many as cycles passed
def test_release_zero_hen_house_and_generate_eggs_1(deploy):
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

    afterRelease = chicken_nft.releaseHenHouse.call(1, {"from": accounts[1]})
    tx = chicken_nft.releaseHenHouse(1, {"from": accounts[1]})
    tx.wait(1)

    assert afterRelease == ()


# revert update Hen House and generate eggs as many as cycles passed
def test_reverts_update_hen_house_and_generate_eggs(deploy):
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

    with reverts("Hen House is empty!"):
        chicken_nft.updateHenHouse.call(1, {"from": accounts[1]})


# Get stake status of rooster or hen
def test_get_stake_status_of_rooster_or_hen(deploy):
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

    tx = chicken_nft.isStaked(1, {"from": accounts[1]})

    assert tx == False


# update Hen House and generate eggs as many as cycles passed
def test_update_hen_house_and_generate_eggs_2(deploy):
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
    chain.sleep(1201)

    check = chicken_nft.checkStakeCycle(2, {"from": accounts[1]})
    assert check >= 0

    data = chicken_nft.updateHenHouse.call(2, {"from": accounts[1]})
    tx = chicken_nft.updateHenHouse(2, {"from": accounts[1]})
    tx.wait(1)

    assert data == (11, 12)

    chain.sleep(600)

    tx = egg_nft.hatchMany(data, {"from": accounts[1]})
    tx.wait(1)


# Open staked hen house and generate eggs as many as cycles passed
def test_release_hen_house_and_generate_eggs_2(deploy):
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

    afterRelease = chicken_nft.releaseHenHouse.call(2, {"from": accounts[1]})
    tx = chicken_nft.releaseHenHouse(2, {"from": accounts[1]})
    tx.wait(1)

    assert afterRelease == (13,)


# update Hen House and generate eggs as many as cycles passed
def test_update_hen_house_and_generate_eggs_3(deploy):
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
    chain.sleep(50000)

    check = chicken_nft.checkStakeCycle(3, {"from": accounts[1]})
    assert check >= 0

    data = chicken_nft.updateHenHouse.call(3, {"from": accounts[1]})
    tx = chicken_nft.updateHenHouse(3, {"from": accounts[1]})
    tx.wait(1)

    assert data[0] >= 13

    tx = egg_nft.hatchMany(data, {"from": accounts[1]})
    tx.wait(1)


# Open staked hen house and generate eggs as many as cycles passed
def test_release_hen_house_and_generate_eggs_3(deploy):
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

    afterRelease = chicken_nft.releaseHenHouse.call(3, {"from": accounts[1]})
    tx = chicken_nft.releaseHenHouse(3, {"from": accounts[1]})
    tx.wait(1)

    assert afterRelease == ()


# returns address of the chicken NFT owner
def test_get_owner_of_chicken_NFT(deploy):
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

    tx = chicken_nft.ownerOf(1, {"from": accounts[1]})

    assert tx == accounts[1]


# test balance of chicken nft
def test_balance_of_chicken_nft(deploy):
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
    balances = chicken_nft.balanceOf(accounts[1], 1, {"from": accounts[1]})
    assert balances == 1


# test balance of chicken nft
def test_revert_balance_of_chicken_nft(deploy):
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
        chicken_nft.balanceOf.call(("0x" + "0" * 40), 1, {"from": accounts[0]})


# test balance of batch chicken nft
def test_balance_of_batch_chicken_nft(deploy):
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
    return_data = chicken_nft.balanceOfBatch([accounts[1]], [1], {"from": accounts[1]})
    assert return_data == (1,)


# set approval for all
def test_revert_set_approval_for_all_true(deploy):
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
        chicken_nft.setApprovalForAll.call(accounts[0], True, {"from": accounts[0]})


# set approval for all
def test_set_approval_for_all_false(deploy):
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

    chicken_nft.setApprovalForAll(accounts[1], False, {"from": accounts[0]})


# set approval for all
def test_set_approval_for_all_true(deploy):
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

    chicken_nft.setApprovalForAll(accounts[1], True, {"from": accounts[0]})


# is approval for all
def test_check_approval_for_all_False(deploy):
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

    data = chicken_nft.isApprovedForAll(accounts[0], accounts[0], {"from": accounts[0]})
    assert data == False


# is approval for all
def test_check_approval_for_all_True(deploy):
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

    data = chicken_nft.isApprovedForAll(accounts[0], accounts[1], {"from": accounts[0]})
    assert data == True


# safeTransferFrom
def test_save_transfer_from(deploy):
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

    balanceBefore = chicken_nft.balanceOf(accounts[2], 1, {"from": accounts[1]})
    assert balanceBefore == 0

    chicken_nft.safeTransferFrom(
        accounts[1], accounts[2], 1, 1, 0, {"from": accounts[1]}
    )
    balanceAfter = chicken_nft.balanceOf(accounts[2], 1, {"from": accounts[1]})
    assert balanceAfter == 1


# set URL for chicken
def test_set_URL_chicken(deploy):
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

    chicken_nft.setURI("testURL", {"from": accounts[0]})


def test_transfer_ownership_chicken(deploy):
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

    chicken_nft.transferOwnership(accounts[1], {"from": accounts[0]})


def test_transfer_ownership_chicken_zero_address(deploy):
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
        chicken_nft.transferOwnership.call(("0x" + "0" * 40), {"from": accounts[1]})
