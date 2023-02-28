// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "utils/inter.sol";

import "interfaces/ibattle.sol";
import "interfaces/ivault.sol";

contract Roosters_Bets is Interconnected {
    using SafeERC20 for IERC20;

    struct BetData {
        uint256 betStakeId;
        uint256 betAmount;
        uint256 timestamp;
    }

    mapping(uint256 => mapping (uint256 => uint256)) internal fightBetPools;
    mapping(address => mapping (uint256 => BetData)) internal usersFightIdToBetData;

    struct Settings {
        uint8 _FEE; // percent of the reward
    }

    Settings settings = Settings({_FEE:1});

    event ClaimReward(
        address indexed userAddress,
        uint256 fightId,
        uint256 rewardAmount,
        uint256 timestamp
    );

    event ReturnBet(
        address indexed userAddress,
        uint256 fightId,
        uint256 returnAmount,
        uint256 timestamp
    );

    constructor() {

    }

    /**
     * @dev Set settings for the contract
     * @dev zero values don't change anything
     * @return current settings
     */
    function setSettings(uint8 FEE) public onlyOwner returns(Settings memory){
        if (FEE != 0 && settings._FEE != FEE){
            settings._FEE = FEE;
        }
        return settings;
    }
    /**
     * @notice Make a bet on a fight
     * @dev user may make multiple bets but only on one participant
     * @param fightId id of the fight from Battle contract
     * @param betStakeId id of the stake participant of the fight
     * @param amountToken bet in smallest units of Token
     */
    function betOnFight(uint256 fightId, uint256 betStakeId, uint256 amountToken) public {

        require(IBattle( IAddressManager(addressManagerAddress).getAddress("battleContractAddress")).getFightData(fightId).winnerStakeId == 0, "Fight is finished!");
        require(usersFightIdToBetData[msg.sender][fightId].betStakeId == 0 || 
            usersFightIdToBetData[msg.sender][fightId].betStakeId == betStakeId, "Bet on just one participant!");
        require(IBattle( IAddressManager(addressManagerAddress).getAddress("battleContractAddress")).getFightData(fightId).stakeId1 == betStakeId ||
            IBattle( IAddressManager(addressManagerAddress).getAddress("battleContractAddress")).getFightData(fightId).stakeId2 == betStakeId, "StakeId is not a participant!");

        bool paymentDone;

        paymentDone = IRHC_Vault(IAddressManager(addressManagerAddress).getAddress("vaultContractAddress")).payBet(msg.sender, amountToken);
        require(paymentDone, "Payment Error!");

        fightBetPools[fightId][betStakeId] += amountToken;

        usersFightIdToBetData[msg.sender][fightId].betAmount += amountToken;
        usersFightIdToBetData[msg.sender][fightId].betStakeId = betStakeId;
        usersFightIdToBetData[msg.sender][fightId].timestamp = block.timestamp;

    }

    /**
     * @notice Bets stats on a fight
     * @dev dynamic information on bet pools
     * @param fightId id of the fight from Battle contract
     * returns stakeId1, pool1, stakeId2, pool2
     */
    function getBetStats(uint256 fightId) public view returns (uint256, uint256, uint256, uint256) {
        
        uint256 pool1;
        uint256 pool2;
        uint256 stakeId1;
        uint256 stakeId2;

        stakeId1 = IBattle( IAddressManager(addressManagerAddress).getAddress("battleContractAddress")).getFightData(fightId).stakeId1;
        stakeId2 = IBattle( IAddressManager(addressManagerAddress).getAddress("battleContractAddress")).getFightData(fightId).stakeId2;

        pool1 = fightBetPools[fightId][stakeId1];
        pool2 = fightBetPools[fightId][stakeId2];

        return (stakeId1, pool1, stakeId2, pool2);
    }

    /**
     * @notice Claim reward for the bet
     * @param fightId id of the fight
     */
    function claimReward(uint256 fightId) public {

        require(IBattle( IAddressManager(addressManagerAddress).getAddress("battleContractAddress")).getFightData(fightId).winnerStakeId != 0, "Fight is not finished!");

        uint256 reward;
        uint256 fee;
        
        reward = _calculateReward(fightId, msg.sender);
        require(reward > 0, "No reward!");

        // clear a claimed bet
        delete usersFightIdToBetData[msg.sender][fightId];

        fee = (reward * settings._FEE) / 100;
        reward = reward - fee;
        // transfer fee to receiver's balance
        // transfer reward to user's available balance
        IRHC_Vault(IAddressManager(addressManagerAddress).getAddress("vaultContractAddress")).claimBetReward(msg.sender, reward, fee);

        emit ClaimReward(msg.sender, fightId, reward, block.timestamp);

    }

    /**
     * @notice Return bet for a canceled fight
     * @dev no fee is paid
     * @param fightId id of the fight
     */
    function returnCanceledFightBet(uint256 fightId) public {

        require(IBattle( IAddressManager(addressManagerAddress).getAddress("battleContractAddress")).getFightData(fightId).stakeId2 == 0, "Fight is not canceled!");

        uint256 returnAmount;

        returnAmount = usersFightIdToBetData[msg.sender][fightId].betAmount;

        // clear a bet
        delete usersFightIdToBetData[msg.sender][fightId];

        // transfer returnAmount
        IRHC_Vault(IAddressManager(addressManagerAddress).getAddress("vaultContractAddress")).returnBet(msg.sender, returnAmount);

        emit ReturnBet(msg.sender, fightId, returnAmount, block.timestamp);

    }

    /**
     * @notice check reward amount of the user
     * @dev a possible reward if bet wins for not initiated fight, or real reward if fight is finished
     * @param fightId id of the fight
     * @param account address of the user who made a bet
     */
    function checkReward(uint256 fightId, address account) public view returns (uint256) {
        uint256 totalBetAmount;
        uint256 reward;
        uint256 fee;
        uint256 betStakeId;

        // no bet, no reward
        if (usersFightIdToBetData[account][fightId].betAmount == 0) {
            return 0;
        }

        IBattle.FightData memory fightData;
        fightData = IBattle( IAddressManager(addressManagerAddress).getAddress("battleContractAddress")).getFightData(fightId);

        if (fightData.winnerStakeId == 0) {
            // fight is not finished yet
            totalBetAmount = fightBetPools[fightId][fightData.stakeId1] + fightBetPools[fightId][fightData.stakeId2];
            betStakeId = usersFightIdToBetData[account][fightId].betStakeId;
            reward = ( totalBetAmount * usersFightIdToBetData[account][fightId].betAmount ) / fightBetPools[fightId][betStakeId];
        
        } else {
            reward = _calculateReward(fightId, account);
        }
        
        fee = (reward * settings._FEE ) / 100;
        reward = reward - fee;

        return reward;
    }

    function _calculateReward(uint256 _fightId, address userAddress) internal view returns (uint256) {

        uint256 totalBetAmount;
        uint256 reward;

        IBattle.FightData memory fightData;
        fightData = IBattle( IAddressManager(addressManagerAddress).getAddress("battleContractAddress")).getFightData(_fightId);

        if (usersFightIdToBetData[userAddress][_fightId].betStakeId == fightData.winnerStakeId) {

            totalBetAmount = fightBetPools[_fightId][fightData.stakeId1] + fightBetPools[_fightId][fightData.stakeId2];

            reward = totalBetAmount * usersFightIdToBetData[userAddress][_fightId].betAmount / fightBetPools[_fightId][fightData.winnerStakeId];

        }
        
        return reward;
    }

}