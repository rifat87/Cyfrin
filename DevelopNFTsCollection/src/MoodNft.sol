// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";

contract MoodNft is ERC721 {
    // errors
    error MoodNft_CantFlipMoodIfNotOwner();

    uint256 private s_tokenCounter;
    string private s_sadSvgUri;
    string private s_happySvgUri;
    

    enum Mood {
        HAPPY, SAD
    }


    mapping(uint256 => Mood) private s_tokenIdToMood;

    constructor(string memory sadSvgUri, string memory happySvgUri) ERC721("Mood NFT", "MN"){
        s_tokenCounter = 0;
        s_sadSvgUri = sadSvgUri;
        s_happySvgUri = happySvgUri;
    }

    function mintNft() public{
        _safeMint(msg.sender, s_tokenCounter);
        s_tokenIdToMood[s_tokenCounter] = Mood.HAPPY;
        s_tokenCounter++;
    }

    function flipMood(uint256 tokenId) public {
        // Fetch the owner of the token
        address owner = ownerOf(tokenId);
        // Only want the owner of NFT to change the mood.
        _checkAuthorized(owner, msg.sender, tokenId);

        if (s_tokenIdToMood[tokenId] == Mood.HAPPY) {
            s_tokenIdToMood[tokenId] = Mood.SAD;
        } else {
            s_tokenIdToMood[tokenId] = Mood.HAPPY;
        }
    }

    function _baseURI() internal pure override returns (string memory) {
        return "data:application/json;base64,";
    }

    function tokenURI(uint256 tokenId) public view override returns ( string memory) {
        string memory imageURI;
        if(s_tokenIdToMood[tokenId] == Mood.HAPPY){
            imageURI = s_happySvgUri;
        }else{
            imageURI = s_sadSvgUri;
        }

        // this portion generates url for the .svg file we can easily test it and get the uri for it.
        return
            string(
                abi.encodePacked(
                _baseURI(),
                Base64.encode(
                    bytes(
                        abi.encodePacked('{"name": "', name(), '", "description": "An NFT that reflects the owners mood.", "attributes":[{"trait_type": "moodiness", "value": 100}], "image": "', imageURI, '"}'
                        )
                    )
                )
            )
        );
    }
}