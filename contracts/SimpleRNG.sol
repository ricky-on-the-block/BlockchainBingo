// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "hardhat/console.sol";

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract SimpleRNG {
    // Seed with an input that depends on deployment time
    uint256 private incrementRNG = block.timestamp;

    // CREATE A RANDOM NUMBER - GENERATE FUNCTION
    // -------------------------------------------------------------
    // Generate a random number (Can be replaced by Chainlink)
    function rng() internal returns (uint256) {
        uint256 rn = uint256(keccak256(abi.encodePacked(incrementRNG)));

        // Increment unchecked to allow wrapping
        unchecked {
            incrementRNG++;
        }

        return rn;
    }
}
