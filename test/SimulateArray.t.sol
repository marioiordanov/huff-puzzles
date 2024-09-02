// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import {HuffConfig} from "foundry-huff/HuffConfig.sol";
import {HuffDeployer} from "foundry-huff/HuffDeployer.sol";
import {NonMatchingSelectorHelper} from "./test-utils/NonMatchingSelectorHelper.sol";

interface SimulateArray {
    function pushh(uint256 num) external;

    function popp() external;

    function read(uint256 index) external view returns (uint256);

    function length() external view returns (uint256);

    function write(uint256 index, uint256 num) external;
}

contract SimulateArrayTest is Test, NonMatchingSelectorHelper {
    SimulateArray public simulateArray;

    function setUp() public {
        simulateArray = SimulateArray(
            HuffDeployer.config().deploy("SimulateArray")
        );
    }

    function testSimpleSimulateArray() external {
        vm.expectRevert(bytes4(keccak256("ZeroArray()")));
        simulateArray.popp();
        (bool success, bytes memory returnData) = address(simulateArray).call(
            abi.encodeWithSelector(SimulateArray.read.selector, 0)
        );
        assert(!success);
        assertEq(bytes4(returnData), bytes4(keccak256("OutOfBounds()")));
        console.log(simulateArray.length());
        simulateArray.pushh(1);
        console.log(simulateArray.length());
        simulateArray.pushh(2);
        console.log(simulateArray.length());
        simulateArray.popp();
        console.log(simulateArray.length());
        simulateArray.popp();
        console.log(simulateArray.length());
        (success, returnData) = address(simulateArray).call(
            abi.encodeWithSelector(SimulateArray.popp.selector)
        );
        assert(!success);
        assertEq(
            bytes4(returnData),
            bytes4(keccak256("ZeroArray()")),
            "Expected the call to revert with custom error 'ZeroArray()' but it didn't "
        );

        simulateArray.pushh(11);
        simulateArray.pushh(21);
        simulateArray.pushh(13);
        assertEq(simulateArray.read(2), 13);
        simulateArray.popp();
        (success, returnData) = address(simulateArray).call(
            abi.encodeWithSelector(SimulateArray.read.selector, 2)
        );
        assert(!success);
        assertEq(
            bytes4(returnData),
            bytes4(keccak256("OutOfBounds()")),
            "Expected the call to revert with custom error 'OutOfBounds()' but it didn't "
        );

        simulateArray.write(0, 100);
        assertEq(simulateArray.read(0), 100);
        vm.expectRevert();
        simulateArray.write(100, 0);
    }

    function testSimulateArray(uint256[] memory array) external {
        vm.expectRevert(bytes4(keccak256("ZeroArray()")));
        simulateArray.popp();

        assertEq(
            simulateArray.length(),
            0,
            "length is initially meant to be 0"
        );

        for (uint256 i; i < array.length; ++i) {
            simulateArray.pushh(array[i]);
            assertEq(simulateArray.read(i), array[i], "Wrong value");
            uint256 writeIndex = bound(array.length, 0, i);
            simulateArray.write(writeIndex, array[i]);
            assertEq(simulateArray.read(writeIndex), array[i], "Wrong value");
            assertEq(simulateArray.length(), i + 1, "Wrong length");
        }

        for (uint256 i = array.length; i > 0; --i) {
            simulateArray.popp();
            vm.expectRevert(bytes4(keccak256("OutOfBounds()")));
            simulateArray.read(i - 1);
            vm.expectRevert(bytes4(keccak256("OutOfBounds()")));
            simulateArray.write(i - 1, array[i - 1]);
            assertEq(simulateArray.length(), i - 1, "Wrong length");
        }

        vm.expectRevert(bytes4(keccak256("ZeroArray()")));
        simulateArray.popp();
    }

    /// @notice Test that a non-matching selector reverts
    function testNonMatchingSelector(bytes32 callData) public {
        bytes4[] memory func_selectors = new bytes4[](5);
        func_selectors[0] = SimulateArray.pushh.selector;
        func_selectors[1] = SimulateArray.popp.selector;
        func_selectors[2] = SimulateArray.read.selector;
        func_selectors[3] = SimulateArray.length.selector;
        func_selectors[4] = SimulateArray.write.selector;

        bool success = nonMatchingSelectorHelper(
            func_selectors,
            callData,
            address(simulateArray)
        );
        assert(!success);
    }
}
