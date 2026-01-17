pragma solidity 0.8.20; //Do not change the solidity version as it negatively impacts submission grading
// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/access/Ownable.sol";
import "./YourToken.sol";

contract Vendor is Ownable {
    /////////////////
    /// Errors //////
    /////////////////

    error InvalidEthAmount();
    error InsufficientVendorTokenBalance(uint256 available, uint256 required);
    error EthTransferFailed(address to, uint256 amount);

    error InvalidTokenAmount();
    error InsufficientVendorEthBalance(uint256 available, uint256 required);

    //////////////////////
    /// State Variables //
    //////////////////////
    uint256 public constant tokensPerEth = 100;
    YourToken public immutable yourToken;

    ////////////////
    /// Events /////
    ////////////////

    event BuyTokens(address indexed buyer, uint256 amountOfETH, uint256 amountOfTokens);
    event SellTokens(address indexed seller, uint256 amountOfTokens, uint256 amountOfETH);

    ///////////////////
    /// Constructor ///
    ///////////////////

    constructor(address tokenAddress) Ownable(msg.sender) {
        yourToken = YourToken(tokenAddress);
    }

    ///////////////////
    /// Functions /////
    ///////////////////

    function buyTokens() external payable {
        if (msg.value == 0) {
            revert InvalidEthAmount();
        }
        uint256 tokensReceived = msg.value * tokensPerEth;
        if (yourToken.balanceOf(address(this)) < tokensReceived) {
            revert InsufficientVendorTokenBalance(yourToken.balanceOf(address(this)), tokensReceived);
        }

        yourToken.transfer(msg.sender, tokensReceived);
        emit BuyTokens(msg.sender, msg.value, tokensReceived);
    }

    function withdraw() public onlyOwner {
        uint256 amount = address(this).balance;
        (bool success, ) = owner().call{ value: amount }("");
        if (!success) {
            revert EthTransferFailed(msg.sender, amount);
        }
    }

    function sellTokens(uint256 amount) public {
        if (amount == 0) {
            revert InvalidTokenAmount();
        }
        uint256 vendorEthAmount = address(this).balance;
        uint256 tokensEthAmount = amount / tokensPerEth;
        if (vendorEthAmount < tokensEthAmount) {
            revert InsufficientVendorEthBalance(vendorEthAmount, tokensEthAmount);
        }

        yourToken.transferFrom(msg.sender, address(this), amount);
        (bool success, ) = msg.sender.call{ value: tokensEthAmount }("");
        if (!success) {
            revert EthTransferFailed(msg.sender, tokensEthAmount);
        }

        emit SellTokens(msg.sender, amount, tokensEthAmount);
    }
}
