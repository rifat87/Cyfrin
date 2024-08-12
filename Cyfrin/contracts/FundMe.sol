
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {PriceConverter} from "./PriceConverter.sol";

// we can use custom error instead of require for more gas optimization and this is the most updated one
error NotOwner();

contract FundMe{
    using PriceConverter for uint256;

    //constant and immutable gives us the ability to optimize the gas cost and constant variable use All capital letter for the variable
    // view function has the gas cost when it is called.
    // for immutable variable we use i_ for better understanding
    uint256 public constant MINIMUM_USD = 5e18;

    address[] public funders;

    mapping(address funders => uint256 amountFunded) public addressToAmountFunded;

    address public immutable i_owner;

    constructor(){
        i_owner = msg.sender;
    }

    function fund() public payable {
        //Allow users to send $
        //Have a minimum $ sent
        // 1. How do we send ETH to this contract?
        require(msg.value.getConversionRate() >= MINIMUM_USD, "didn't sent enough ETHH");
        funders.push(msg.sender);

        addressToAmountFunded[msg.sender] += msg.value;
    }

    //withdraw the fund
    function withdraw() public onlyOwner{

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
        // payable(msg.sender).transfer(address(this).balance);

        // //send
        // bool sendSuccess = payable (msg.sender).send(address(this).balance);
        // require(sendSuccess, "Send failed");

        //call is the main one
        (bool callSuccess, )= payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess, "Call failed");
    }

    modifier onlyOwner() {
        // for  withdraw we have to varify it is the owner
        // require(msg.sender == i_owner, "Must be owner!");
        if(msg.sender != i_owner) { revert NotOwner();} // This is more gas efficient
        _;
    }

    receive() external payable { 
        fund();
    }
    fallback() external payable { 
        fund();
    }

}