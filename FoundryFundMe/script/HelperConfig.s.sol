// SPDX-License-Identifier: MIT

// 1. Deploy mocks when we are on a local anvil chain
// 2. Keep tract of contract address across differenct chians
// Sepolia ETH/USD
// Mainnet ETH/USD

pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";

contract HelperConfig is Script{
    //If we are on a local anvil, we deploy mocks
    // otherwise, grab the existing address from the live networkkkk
    NetworkConfig public activeNetworkConfig;

    struct NetworkConfig {
        address priceFeed; // ETH/USD price feed address
    }

    constructor() {
        // 11155111 which is the sepolia chain id
        if (block.chainid == 11155111){
            activeNetworkConfig = getSepoliaEthConfig();
        } else if ( block.chainid == 1 ){
            activeNetworkConfig = getMainnetEthConfig();
        }
        else {
            activeNetworkConfig = getAnvilEthConfig();
        }
    }
    function getSepoliaEthConfig() public pure returns(NetworkConfig memory) {
        //price feed address
        NetworkConfig memory sepoliaConfig = NetworkConfig({
            priceFeed: 0x694AA1769357215DE4FAC081bf1f309aDC325306
        });
        return sepoliaConfig;
    }
    
    //mainnet config
    function getMainnetEthConfig() public pure returns(NetworkConfig memory) {
        //price feed address
        NetworkConfig memory ethConfig = NetworkConfig({
            priceFeed: 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419 // here we are going to paste the id from docs.chain.link and copy from 
        });
        return ethConfig;
    }

    function getAnvilEthConfig() public returns(NetworkConfig memory) {
        // price feed address

        // 1. Deploy the mocks
        // 2. Return the mock adress

        vm.startBroadcast();
        
        vm.stopBroadcast();
    }
}