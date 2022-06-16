// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IBingo {
    event GameJoined(address indexed playerAddress, string playerBoard);
    event GameStarted(uint256 timestamp);
    event NumberDrawn(uint8 number);
    event GameWon(
        uint256 timestamp,
        address indexed winner,
        uint256 awardAmount
    );

    function joinGame() external payable;

    function startGame() external;

    function drawNumber() external;

    function claimBingo(uint256 tokenId) external returns (bool isBingo);
}
