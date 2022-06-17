// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IBingo {
    event NumberDrawn(uint8 number);
    event GameWon(
        uint256 timestamp,
        address indexed winner,
        uint256 awardAmount
    );


    function drawNumber() external;

    function claimBingo(uint256 tokenId) external returns (bool isBingo);
}
