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

    //////////////////////
    /// State Variables //
    //////////////////////
    uint256 public constant tokensPerEth = 100;
    YourToken public immutable yourToken;

    ////////////////
    /// Events /////
    ////////////////

    event BuyTokens(address indexed buyer, uint256 amountOfETH, uint256 amountOfTokens);

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
        if (success == false) {
            revert EthTransferFailed(msg.sender, amount);
        }
    }

    function sellTokens(uint256 amount) public {}
}
