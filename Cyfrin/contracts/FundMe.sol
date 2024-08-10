
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

contract FundMe{
    function fund() public payable {
        //Allow users to send $
        //Have a minimum $ sent
        // 1. How do we send ETH to this contract?
        require(msg.value > 1e18, "didn't sent enough ETHH");
    }
    //function withdraw() public{}

    function getPrice() public {
        //Address: 0x694AA1769357215DE4FAC081bf1f309aDC325306
        //ABI
    }
    function getConversionRate() public {

    }
}