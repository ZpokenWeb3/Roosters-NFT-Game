// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

interface IRHC_Vault {
    function payForEggs(address userAddress, uint256 amountToken) external returns (bool);
    function payForRessurection(address userAddress, uint256 amountToken) external returns (bool);
    function payCancelFight(address userAddress, uint256 amountToken) external returns (bool);
    function payForCraft(address userAddress, uint256 amountToken) external returns (bool);
    function payBet(address userAddress, uint256 amountToken) external returns (bool);
    function claimBetReward(address userAddress, uint256 reward, uint256 fee) external;
    function returnBet(address userAddress, uint256 returnAmount) external;
    function rewardAccount(address userAddress, uint256 amountToken) external returns (bool);
    function makePayment(address userAddress, uint256 amountToken) external returns (bool);
}