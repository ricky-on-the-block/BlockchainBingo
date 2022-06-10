// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IBingo {
    function joinGame() external;
    function startGame() external;
    function drawNumber() external;
    function claimBingo() external;
}