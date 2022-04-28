//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./interfaces/aave/FlashLoanReceiverBase.sol";

contract TestAaveFlashLoan is FlashLoanReceiverBase {
    using SafeMath for uint256;

    event Log(string message, uint256 val);

    constructor(ILendingPoolAddressesProvider _addressProvider)
        public
        FlashLoanReceiverBase(_addressProvider)
    {}

    function testFlashLoan(address asset, uint256 amount) external {
        //this function we will call to receive flashloan
        uint256 bal = IERC20(asset).balanceOf(address(this));
        require(bal > amount, "bal <= amount");

        address receiver = address(this);
        address[] memory assets = new address[](1);
        assets[0] = asset;

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = amount;

        uint256[] memory modes = new uint256[](1);
        modes[0] = 0;

        address onBehalfOf = address(this);

        bytes memory params = ""; // extra data to pass abi.encode(...)
        uint16 referralCode = 0;

        LENDING_POOL.flashLoan(
            receiver, // address of contract that receives the tokens we want to borrow
            assets, // array of tokens we want to borrow
            amounts, // amount of tokens we want to borrow
            modes, // modes that are available // 0 = no debt, 1 = stable, 2 = variable/// 0 = pay all loaned // we are gonna be paying back in the same transaction so we use 0
            onBehalfOf, // this is an address that will receive debt in case mode is == 1 or 2
            params,
            referralCode
        );
    }

    function executeOperation(
        //this function will be callback by Aave protocol
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata premiums, // the fees we need to pay for borrowing
        address initiator, // address that executed the flashloan this contract
        bytes calldata params //data that we want to pass to this function
    ) external override returns (bool) {
        // do stuff here (arbitrage, liquidation, expoit if you are a hacker)
        for (uint256 i = 0; i < assets.length; i++) {
            emit Log("borrowed", amounts[i]);
            emit Log("fee", premiums[i]);

            uint256 amountOwing = amounts[i].add(premiums[i]);
            IERC20(assets[i]).approve(address(LENDING_POOL), amountOwing);
        }
        // repay Aave
        return true;
    }
}
