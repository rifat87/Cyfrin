// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

// import {assertEq} from "../lib/ds-test/src/test.sol";
import "../lib/ds-test/src/test.sol";

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../src/FundMe.sol";
contract FundMeTest is Test{
    // Here the setUp() function always runs first

    /* Context: In Foundry, assertEq is commonly used in tests to assert that two values are equal. However, this function is part of the DSTest library, which provides various assertion functions for testing purposes.*/
    FundMe fundMe;
    function setUp() external {
        fundMe = new FundMe();
    }

    function testMinimumDollarIsFive() public {
        assertEq(fundMe.MINIMUM_USD(), 5e18);

        // console.log("Hey, Rifat");
        // console.log(number);
        // console.log(number);
        // assertEq(number, 2);
    }

    function testOwnerIsMsgSender() public {
        console.log(fundMe.i_owner());
        console.log(". this is msg sender", msg.sender);
        // assertEq(fundMe.i_owner(), msg.sender); this will not same because, the fundMe.i_owner() is actually our local device and the msg.sender is the acutal owner who actually transacts.

        assertEq(fundMe.i_owner(), address(this)); // Here the this will check with the current address.
    }

    //What can we do to work with addresses outside out system?
    // 1. Unit
    //      - Testing a specific part of our code
    // 2. Integration
    //      - Testing our code works with other parts of our code
    // 3. Forked
    //      - Testing our code on a simulated real environment
    // 4. staging 
    //      - Testing our code in a real environment that is not prod
    function testPricedFeedVersionIsAccurate() public {
        uint256 version = fundMe.getVersion();
        console.log("The version is: ", version);
        assertEq(version, 4);
    }

    //Modular deployments
    //Modular testing
}