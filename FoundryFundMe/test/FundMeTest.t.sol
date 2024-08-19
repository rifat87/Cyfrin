// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import "ds-test/test.sol";
import {Test, console} from "forge-std/Test.sol";
contract FundMeTest {
    // Here the setUp() function always runs first

    /* Context: In Foundry, assertEq is commonly used in tests to assert that two values are equal. However, this function is part of the DSTest library, which provides various assertion functions for testing purposes.*/
    uint256 number = 1;
    function setUp() external {
        number = 2;
    }

    function testDemo() public {
        console.log("Hey, Rifat");
        console.log(number);
        assertEq(number, 2);
    }
}