// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "utils/inter.sol";

contract RHC_Vault is Interconnected {
    using SafeERC20 for IERC20;

    mapping(address => uint256) public usersAvailableBalances;

    address payable private receiverAddress;

    event Deposit(
        address indexed userAddress,
        uint256 depositAmount,
        uint256 timestamp
    );

    event Withdraw(
        address indexed userAddress,
        uint256 withdrawAmount,
        uint256 timestamp
    );
    
    // RHC token (Mumbai Testnet)
    IERC20 internal depositToken = IERC20(0x374D22d3f2e5838010F19D0D21260d29faaE8539);

    constructor() {

        receiverAddress = payable(msg.sender);

    }

    /**
     * @notice Set address for auto and manual receiving eth
     * @param _newReceiverAddress address of the receiver
     */
    function setReceiverAddress(address _newReceiverAddress) public onlyOwner {
        require(_newReceiverAddress != address(0), "Receiver cannot be zero address!");
        receiverAddress = payable(_newReceiverAddress);
    }

    /**
     * @dev Withdraw all eth from the contract to Receiver address
     */
    function _withdrawAll() private {
        if (address(this).balance > 0) {
            receiverAddress.transfer(address(this).balance);
        }
    }

    /**
     * @notice Set the token for deposits
     * @param _depositTokenAddress address of the deposit token
     */
    function setDepositToken(address _depositTokenAddress) public onlyOwner {
        depositToken = IERC20(_depositTokenAddress);
    }

    /**
     * @notice deposit tokens to the contract
     * @param amountToken amount in smallest units of Token
     */
    function deposit(uint256 amountToken) public {

        // token approve is required before depositing
        depositToken.safeTransferFrom(msg.sender, address(this), amountToken);

        usersAvailableBalances[msg.sender] += amountToken;

        emit Deposit(msg.sender, amountToken, block.timestamp);
    }

    /**
     * @notice withdraw tokens from the contract
     * @param amountToken amount in smallest units of Token
     */
    function withdraw(uint256 amountToken) public {

        require(usersAvailableBalances[msg.sender] >= amountToken, "Not enough balance!");
        
        usersAvailableBalances[msg.sender] -= amountToken;

        depositToken.safeTransfer(msg.sender, amountToken);

        emit Withdraw(msg.sender, amountToken, block.timestamp);
    }

    /**
     * @notice get user's available balance
     * @param userAddress user's address
     */
    function getBalance(address userAddress) public view returns (uint256){
        return usersAvailableBalances[userAddress];
    }

    function makePayment(address userAddress, uint256 amountToken) external returns (bool) {

        require(msg.sender == IAddressManager(addressManagerAddress).getAddress("eggContractAddress") ||
                msg.sender == IAddressManager(addressManagerAddress).getAddress("craftContractAddress") ||
                msg.sender == IAddressManager(addressManagerAddress).getAddress("chickenContractAddress") ||
                msg.sender == IAddressManager(addressManagerAddress).getAddress("itemContractAddress") ||
                msg.sender == IAddressManager(addressManagerAddress).getAddress("spellContractAddress") ||
                msg.sender == IAddressManager(addressManagerAddress).getAddress("battleContractAddress"));

        bool paymentDone;
        paymentDone = _makePayment(userAddress, amountToken);
        return paymentDone;
    }

    function payForEggs(address userAddress, uint256 amountToken) external onlyEggContract returns (bool) {

        bool paymentDone;
        paymentDone = _makePayment(userAddress, amountToken);
        return paymentDone;
    }

    function payForCraft(address userAddress, uint256 amountToken) external onlyCraftContract returns (bool) {

        bool paymentDone;
        paymentDone = _makePayment(userAddress, amountToken);
        return paymentDone;
    }

    function payForRessurection(address userAddress, uint256 amountToken) external onlyChickenContract returns (bool) {

        bool paymentDone;
        paymentDone = _makePayment(userAddress, amountToken);
        return paymentDone;
    }

    function payCancelFight(address userAddress, uint256 amountToken) external onlyBattleContract returns (bool) {

        bool paymentDone;
        paymentDone = _makePayment(userAddress, amountToken);
        return paymentDone;
    }

    function payBet(address userAddress, uint256 amountToken) external onlyBetsContract returns (bool) {

        if (usersAvailableBalances[userAddress] <= amountToken) {return false;}

        usersAvailableBalances[userAddress] -= amountToken;
        // Total betting pool
        usersAvailableBalances[IAddressManager(addressManagerAddress).getAddress("betsContractAddress")] += amountToken;

        return true;
    }

    function claimBetReward(address userAddress, uint256 reward, uint256 fee) external onlyBetsContract {

        usersAvailableBalances[userAddress] += reward;
        usersAvailableBalances[receiverAddress] += fee;

        _reduceBetPool(reward + fee);
    }

    function returnBet(address userAddress, uint256 returnAmount) external onlyBetsContract {

        usersAvailableBalances[userAddress] += returnAmount;

        _reduceBetPool(returnAmount);
    }

    function _reduceBetPool(uint256 amountToDeduct) internal {
        // keeping track of betting pool, avoid rounding errors
        if (usersAvailableBalances[IAddressManager(addressManagerAddress).getAddress("betsContractAddress")] >= amountToDeduct) {
            usersAvailableBalances[IAddressManager(addressManagerAddress).getAddress("betsContractAddress")] -= amountToDeduct;
        } else {
            usersAvailableBalances[IAddressManager(addressManagerAddress).getAddress("betsContractAddress")] = 0;
        }
    }

    function _makePayment(address userAddress, uint256 amountToken) internal returns (bool) {

        if (usersAvailableBalances[userAddress] <= amountToken) {return false;}

        usersAvailableBalances[userAddress] -= amountToken;
        usersAvailableBalances[receiverAddress] += amountToken;

        return true;
    }

    function rewardAccount(address userAddress, uint256 amountToken) external returns (bool) {

        require(msg.sender == IAddressManager(addressManagerAddress).getAddress("eggContractAddress") ||
                msg.sender == IAddressManager(addressManagerAddress).getAddress("chickenContractAddress") ||
                msg.sender == IAddressManager(addressManagerAddress).getAddress("itemContractAddress") ||
                msg.sender == IAddressManager(addressManagerAddress).getAddress("spellContractAddress") ||
                msg.sender == IAddressManager(addressManagerAddress).getAddress("battleContractAddress"));

        usersAvailableBalances[userAddress] += amountToken;

        return true;
    }

}