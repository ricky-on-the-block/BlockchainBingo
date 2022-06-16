// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

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
