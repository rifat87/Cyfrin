// SPDX-License-Identifier: MIT

// To install openZeppelin use: forge install OpenZeppelin/openzeppelin-contracts --no-commit

// Then add the remappings 
// Now import the library
pragma solidity ^0.8.18;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract BasicNft is ERC721{
    uint256 private s_tokenCounter;
    mapping(uint256 => string) private s_tokenIdToUri;

    constructor() ERC721("Dogie", "DOG") {
        s_tokenCounter = 0;
    }

    function mintNft(string tokenUri) public {
        s_tokenIdToUri[s_tokenCounter] = tokenUri;
        _safeMint(msg.sender, s_tokenCounter);
        s_tokenCounter++;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) { // Here we are goign to send the tokenId and it will generate a URL/URI that's why retrun style is string memory and this function is taken from ERC721 which is an abstract fujnction so that we use the override term.
        return s_tokenIdToUri[tokenId];
    }
}