const { ethers } = require("ethers");

async function connect() {
    if (typeof window.ethereum !== "undefined") {
        await ethereum.request({
            "method": "eth_requestAccounts",
            "params": []
        });
        console.log("Connected to MetaMask successfully!");
    }
}


async function execution() {
    // address 
    // contract ABI (blueprint to interact with a contract)
    // function 
    // node connection with metamask
}

module.exports = {
    connect, execute,
};