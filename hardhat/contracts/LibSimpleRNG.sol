// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

library LibSimpleRNG {
    // Seed with an input that depends on deployment time
    struct SimpleRNGSeed {
        uint256 incrementRNG;
    }

    // uint256 private incrementRNG = block.timestamp;

    // CREATE A RANDOM NUMBER - GENERATE FUNCTION
    // -------------------------------------------------------------
    // Generate a random number (Can be replaced by Chainlink)
    function rng(SimpleRNGSeed storage simpleRNGSeed)
        internal
        returns (uint256)
    {
        uint256 rn = uint256(
            keccak256(abi.encodePacked(simpleRNGSeed.incrementRNG))
        );

        // Increment unchecked to allow wrapping
        unchecked {
            simpleRNGSeed.incrementRNG++;
        }

        return rn;
    }
}
