// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {FundMe} from "../src/FundMe.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployFundMe is Script{
    function run() external returns (FundMe){
        // Before startBroadcast -> Not a "Real" tx
        HelperConfig helperConfig = new HelperConfig();

        //(address ehtUSDPriceFeed, , , ) = helperConfig.activeNetworkConfig(); // because its a sruct that's why we use the parenthesis
        address ethUsdPriceFeed = helperConfig.activeNetworkConfig(); // because we have only one value that's why.

        //After startBroadcast -> Real tx!
        vm.startBroadcast();
        FundMe fundMe = new FundMe(ethUsdPriceFeed);
        vm.stopBroadcast();   
        return fundMe;
    }
}
