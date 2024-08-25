// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

// to encrypt the private to instead of storing in .env file we will use ERC-2335: BLS12-381 Keystore

// cast wallet import defaultKey --interactive is for storing the private key.
import {Script} from "forge-std/Script.sol";
import {SimpleStorage} from "../src/SimpleStorage.sol";


contract DeploySimpleStorage is Script{
    function run() external returns (SimpleStorage) {
        vm.startBroadcast();// everything after the vm, send to rpc and when we are done we use vm.StopBradcast();

        SimpleStorage simpleStorage = new SimpleStorage();

        vm.stopBroadcast();
        return simpleStorage;
    }

    constructor() {
        
    }
}