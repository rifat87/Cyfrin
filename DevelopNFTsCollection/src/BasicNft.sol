// SPDX-License-Identifier: MIT

// To install openZeppelin use: forge install OpenZeppelin/openzeppelin-contracts --no-commit

// Then add the remappings 
// Now import the library
pragma solidity ^0.8.18;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract BasicNft is ERC721{
    uint256 private s_tokenCounter;

    constructor() ERC721("Dogie", "DOG") {
        s_tokenCounter = 0;
    }
}