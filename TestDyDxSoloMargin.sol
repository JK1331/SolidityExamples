//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./interfaces/dydx/DydxFlashloanBase.sol";
import "./interfaces/dydx/ICallee.sol";

contract TestDyDxSoloMargin is ICallee, DydxFlashloanBase {
    address private constant SOLO = 0x1E0447b19BB6EcFdAe1e4AE1694b0C3659614e4e; //conract we will get flashloan from

    address public flashUser;

    event Log(string message, uint256 val);

    struct MyCustomData {
        address token;
        uint256 repayAmount;
    }

    // This is a function we call
    function initiateFlashLoan(address _token, uint256 _amount) external {
        ISoloMargin solo = ISoloMargin(SOLO); // dydx contract that we will call for flashloan

        /* 
        0 WETH
        1 SAI
        2 USDC
        3 DAI
          */
        uint256 marketId = _getMarketIdFromTokenAddress(SOLO, _token); // id for token we are borrowing

        // Calculate repay amount (_amount + (2 wei))
        uint256 repayAmount = _getRepaymentAmountInternal(_amount);
        IERC20(_token).approve(SOLO, repayAmount);

        /*
        1. Withdraw
        2. Call callFunction
        3. Deposit back
        */

        Actions.ActionArgs[] memory operations = new Actions.ActionArgs[](3);
        operations[0] = _getWithdrawAction(marketId, _amount);
        operations[1] = _getCallAction(
            abi.encode(MyCustomData({token: _token, repayAmount: repayAmount}))
        );
        operations[2] = _getDepositAction(marketId, repayAmount);

        Account.Info[] memory accountInfos = new Account.Info[](1);
        accountInfos[0] = _getAccountInfo();

        solo.operate(accountInfos, operations);
    }

    // This function will be calledback by DyDx
    function callFunction(
        address sender,
        Account.Info memory account,
        bytes memory data
    ) public override {
        require(msg.sender == SOLO, "! Not DyDx solo contract");
        require(sender == address(this), "!This contract");
        // Now we decode data that were passed as input
        MyCustomData memory mcd = abi.decode(data, (MyCustomData));
        uint256 repayAmount = mcd.repayAmount;

        uint256 bal = IERC20(mcd.token).balanceOf(address(this));
        require(bal >= repayAmount, "bal < repay");

        // We write our custom code what to do with flashloan here
        flashUser = sender;
        emit Log("bal", bal);
        emit Log("repay", repayAmount);
        emit Log("bal - repay", bal - repayAmount);
    }
}
