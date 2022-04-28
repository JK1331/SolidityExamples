// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

// calls B, sends 100 wei
//       B calls C, send 50 wei
// A ----> B -----> C
//                  msg.sender = B
//                  msg.value = 50
//                  execute code on C's state variables
//                  use ETH in C

// A calls B, send 100 wei
//         B delegatecall C
// A ---> B -----> C
//                 msg.sender = A
//                 msg.value = 100
//                 execute code on B's state variables
//                 use ETH in B

contract TestDelegateCall {
    uint256 public num;
    address public sender;
    uint256 public value;

    function setVars(uint256 _num) external payable {
        num = _num;
        sender = msg.sender;
        value = msg.value;
    }
}

contract DelegateCall {
    uint256 public num;
    address public sender;
    uint256 public value;

    function setVars(address _test, uint256 _num) external payable {
        //    _test.delegatecall(abi.encodeWithSignature("setVars(uint 256)", _num));  another way below
        (bool success, bytes memory data) = _test.delegatecall(
            abi.encodeWithSelector(TestDelegateCall.setVars.selector, _num)
        );
        require(success, "Delegatecall failed"); //If we use delegatecall to update our contracts logic all STATE VARIABLES MUST BE THE SAME AS IN CALLED CONTRACT else vuln. ethernaut
    }
}
