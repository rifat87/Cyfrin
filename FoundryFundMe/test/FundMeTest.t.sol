// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

// import {assertEq} from "../lib/ds-test/src/test.sol";
import "../lib/ds-test/src/test.sol";

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../src/FundMe.sol";
import {DeployFundMe} from "../script/DeployFundMe.s.sol";

contract FundMeTest is Test{
    // Here the setUp() function always runs first

    /* Context: In Foundry, assertEq is commonly used in tests to assert that two values are equal. However, this function is part of the DSTest library, which provides various assertion functions for testing purposes.*/
    FundMe fundMe;

    address USER = makeAddr("user");
    uint256 constant SEND_VALUE = 0.1 ether;//100000000000000000
    uint256 constant STARTING_BALANCE = 10 ether;
    uint256 constant GAS_PRICE = 1;

    function setUp() external {
        // fundMe = new FundMe(0x694AA1769357215DE4FAC081bf309aDC325306);
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();

        vm.deal(USER, STARTING_BALANCE);
    }

    function testMinimumDollarIsFive() public {
        assertEq(fundMe.MINIMUM_USD(), 5e18);

        // console.log("Hey, Rifat");
        // console.log(number);
        // console.log(number);
        // assertEq(number, 2);
    }

    function testOwnerIsMsgSender() public {
        console.log(fundMe.getOwner());
        console.log(". this is msg sender", msg.sender);
        // assertEq(fundMe.i_owner(), msg.sender); this will not same because, the fundMe.i_owner() is actually our local device and the msg.sender is the acutal owner who actually transacts.

        assertEq(fundMe.getOwner(), msg.sender); // Here the this will check with the current address.
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

    function testFundFailsWithoutEnoughETH() public {
        vm.expectRevert(); // Hey, the next line, should revert;
        // assert(This tx fails/reverts)

        fundMe.fund(); // send 0 value
    } 

    function testFundUpdatesFunddedDataStructure() public{
        vm.prank(USER);// The next TX will be sent by USER
        
        fundMe.fund{value: SEND_VALUE}();

        uint256 amontFunded = fundMe.getAddressToAmountFunded(USER);
        assertEq(amontFunded, SEND_VALUE);
    }

    function testAddsFunderToArrayOfFunders() public {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE} ();

        address funder = fundMe.getFunder(0);

        assertEq(funder, USER);
    }

    modifier funded() {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        _;
    }
    function testOnlyOwnerCanWithdraw() public funded{
        vm.prank(USER);
        vm.expectRevert();
        fundMe.withdraw();
    }

    function testWithDrawWithASingleFunder() public funded {
        // Arrange
        uint256 startingOwnerBalace = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        // Act
        // uint256 gasStart = gasleft(); // 100
        // vm.txGasPrice(GAS_PRICE);
        vm.prank(fundMe.getOwner()); // c:200 
        fundMe.withdraw(); // should have spent gass

        // uint256 gasEnd = gasleft();
        // uint256 gasUsed = (gasStart-gasEnd) * tx.gasprice;
        // console.log(gasUsed);

        //Assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;
        assertEq(endingFundMeBalance, 0);
        assertEq(startingFundMeBalance + startingOwnerBalace, endingOwnerBalance);
    }

    function testWithdrawFromMultipleFunders() public funded {
        // Arrange
        
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;

        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            // vm.prank new address
            // vm.deal new address
            //address()
            hoax(address(i), SEND_VALUE);  // don't know what is hoax

            fundMe.fund{value: SEND_VALUE}();
            // fud the fundMe

        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;


        // Act
        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();
        vm.stopPrank();

        // Assert
        assert(address(fundMe).balance == 0);
        assert(startingFundMeBalance + startingOwnerBalance == fundMe.getOwner().balance);
    }

    function testWithdrawFromMultipleFundersCheaper() public funded {
        // Arrange
        
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;

        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            // vm.prank new address
            // vm.deal new address
            //address()
            hoax(address(i), SEND_VALUE);  // don't know what is hoax

            fundMe.fund{value: SEND_VALUE}();
            // fud the fundMe

        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;


        // Act
        vm.startPrank(fundMe.getOwner());
        fundMe.cheaperWithdraw();
        vm.stopPrank();

        // Assert
        assert(address(fundMe).balance == 0);
        assert(startingFundMeBalance + startingOwnerBalance == fundMe.getOwner().balance);
    }
}