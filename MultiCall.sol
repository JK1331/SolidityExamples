// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract TestMulticall {
    function func1() external view returns (uint256, uint256) {
        return (1, block.timestamp);
    }

    function func2() external view returns (uint256, uint256) {
        return (2, block.timestamp);
    }

    function getData1() external pure returns (bytes memory) {
        // abi.encodeWithSignature("func1()");
        return abi.encodeWithSelector(this.func1.selector); //the same functionality
    }

    function getData2() external pure returns (bytes memory) {
        return abi.encodeWithSelector(this.func2.selector);
    }
}

contract MultiCall {
    function multiCall(address[] calldata targets, bytes[] calldata data)
        external
        view
        returns (bytes[] memory)
    {
        require(targets.length == data.length, "target length != data length");
        bytes[] memory results = new bytes[](data.length);

        for (uint256 i; i < targets.length; i++) {
            (bool success, bytes memory result) = targtes[i].staticcall(
                data[i]
            );
            require(success, "call failed");
            results[i] = result;
        }

        return results;
    }
}

//bytes[]: 0x00000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000062286f39,0x00000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000062286f39
// the output of multicall function returns numbers and timestamp which is same
// When multicalling we need to inser the same address to address[] twice
// We can make more querries in single function call MULTICALL
