// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test} from "forge-std/Test.sol";
import {DeployBasicNft} from "../script/DeployBasicNft.s.sol";
import {BasicNft} from "../src/BasicNft.sol";

contract BasicNftTest is Test {
    DeployBasicNft public deployer;
    BasicNft public basicNft;
    function setUp() public {
        deployer = new DeployBasicNft();
        basicNft = deployer.run();
    }

    function testNameIsCorrect() public view {
        string memory expectedName = "Rifat";
        string memory actualName = basicNft.name();

        // Array of bytes
        // uint256, bool, address bytes32 can be compared but we can not compare array with array like the string.
        // so the assert(expectedName == actualName); will give use an error
        // so for comparig the array in solidty we can use Hash for those string which will then compared.
        assert(expectedName == actualName);
    }
}