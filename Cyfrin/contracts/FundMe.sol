
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {PriceConverter} from "./PriceConverter.sol";

contract FundMe{
    using PriceConverter for uint256;

    uint256 public minimumUsd = 5e18;

    address[] public funders;

    mapping(address funders => uint256 amountFunded) public addressToAmountFunded;

    function fund() public payable {
        //Allow users to send $
        //Have a minimum $ sent
        // 1. How do we send ETH to this contract?
        require(msg.value.getConversionRate() >= minimumUsd, "didn't sent enough ETHH");
        funders.push(msg.sender);

        addressToAmountFunded[msg.sender] += msg.value;
    }

    //withdraw the fund
    function withdraw() public{
        for (uint256 funderIndex = 0; funderIndex < funders.length; funderIndex++) 
        {
            address funder =funders[funderIndex];
            addressToAmountFunded[funder] = 0;    
        }

            // reset the array
        funders = new address[](0);

        //transer
        // send
        // call


        //msg.sender = address
        //payable(msg.sender) = payable address
        payable(msg.sender).transfer(address(this).balance);
    }
}