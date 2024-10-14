// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.18;

// import {Test} from "forge-std/Test.sol";
// import {DeployOurToken} from "../script/DeployOurToken.s.sol";
// import {OurToken} from "../src/OurToken.sol";
// contract OurTokenTest is Test {
//     OurToken public ourToken;
//     DeployOurToken public deployer;

//     address bob = makeAddr("bob");
//     address alice = makeAddr("alice");

//     uint256 public constant STARTING_BALANCE = 100 ether;
//     function setUp() public {
//         deployer = new DeployOurToken();
//         ourToken = deployer.run();

//         // Impersonate the owner
//         vm.prank(msg.sender);
//         ourToken.transfer(bob, STARTING_BALANCE);
//     }

//     function testBobBalance() public {
//         assertEq(STARTING_BALANCE, ourToken.balanceOf(bob));
//     }

//     function testAllowancesWorks() public {
//         uint256 initialAllowance = 1000;

//         // Bob approves Alice to spend tokens on her behalf
//         vm.prank(bob);
//         ourToken.approve(alice, initialAllowance);

//         uint256 transferAmount = 500;

//         vm.prank(alice);
//         ourToken.transferFrom(bob, alice, transferAmount);

//         assertEq(ourToken.balanceOf(alice), transferAmount);
//         assertEq(ourToken.balanceOf(bob), STARTING_BALANCE - transferAmount);
//     }
// }



pragma solidity ^0.8.19;

import {DeployOurToken} from "../script/DeployOurToken.s.sol";
import {OurToken} from "../src/OurToken.sol";
import {Test, console} from "forge-std/Test.sol";
import {StdCheats} from "forge-std/StdCheats.sol";

contract OurTokenTest is StdCheats, Test {
    OurToken public ourToken;
    DeployOurToken public deployer;
    address alice = makeAddr("alice");
    address bob = makeAddr("bob");

    function setUp() public {
        deployer = new DeployOurToken();
        ourToken = deployer.run();
    }

    function testInitialSupply() public {
        assertEq(ourToken.totalSupply(), deployer.INITIAL_SUPPLY());
    }

    function testTransfer() public {
        // Transfer tokens from the deployer to Alice
        vm.prank(address(this));
        ourToken.transfer(alice, 10);

        // Verify that the transfer was successful
        assertEq(ourToken.balanceOf(alice), 10);
        assertEq(ourToken.balanceOf(address(this)), deployer.INITIAL_SUPPLY() - 10);
    }

    function testTransferFrom() public {
        // Set an allowance for Bob to transfer tokens from Alice
        vm.prank(alice);
        ourToken.approve(bob, 5);

        // Transfer tokens from Alice to Bob
        vm.prank(bob);
        ourToken.transferFrom(alice, bob, 3);

        // Verify that the transfer was successful
        assertEq(ourToken.balanceOf(alice), 7);
        assertEq(ourToken.balanceOf(bob), 3);
    }

    function testApprove() public {
        // Set an allowance for Bob to transfer tokens from Alice
        vm.prank(alice);
        ourToken.approve(bob, 5);

        // Verify that the allowance was set correctly
        assertEq(ourToken.allowance(alice, bob), 5);
    }

    function testDecreaseAllowance() public {
        // Set an initial allowance for Bob to transfer tokens from Alice
        vm.prank(alice);
        ourToken.approve(bob, 5);

        // Decrease the allowance
        vm.prank(alice);
        ourToken.approve(bob, 3);

        // Verify that the allowance was decreased correctly
        assertEq(ourToken.allowance(alice, bob), 3);
    }

    function testTransferEvent() public {
        // Set up the expectation for the Transfer event
        vm.expectEmit(true, true, true, true);
        vm.prank(address(this));
        ourToken.transfer(alice, 10);

        // Verify that the event was emitted
        vm.verifyEmit();
    }

    function testApprovalEvent() public {
        // Set up the expectation for the Approval event
        vm.expectEmit(true, true, true, true);
        vm.prank(alice);
        ourToken.approve(bob, 5);

        // Verify that the event was emitted
        vm.verifyEmit();
    }
}