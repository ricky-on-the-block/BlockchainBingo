// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "hardhat/console.sol";

import "contracts/IBingo.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Bingo is IBingo, Ownable {
    // Long-term: move this to NFT generation. For now, a double mapping works
    enum BoardPositions {
        B0, B1, B2, B3, B4,
        I0, I1, I2, I3, I4,
        N0, N1, N2, N3, N4,
        G0, G1, G2, G3, G4,
        O0, O1, O2, O3, O4
    }

    struct BoardElement {
        uint8 value;        // must fall within min & max value for that column
        bool  hasBeenDrawn;
    }
    
    mapping(address => mapping(BoardPositions => BoardElement)) public playerGameBoards;

    // Per the Standard US Bingo Rules
    uint8 constant B_MIN_VALUE = 1;
    uint8 constant B_MAX_VALUE = 15;
    uint8 constant I_MIN_VALUE = 16;
    uint8 constant I_MAX_VALUE = 30;
    uint8 constant N_MIN_VALUE = 31;
    uint8 constant N_MAX_VALUE = 45;
    uint8 constant G_MIN_VALUE = 46;
    uint8 constant G_MAX_VALUE = 60;
    uint8 constant O_MIN_VALUE = 61;
    uint8 constant O_MAX_VALUE = 75;

    function joinGame() external {
        console.log("joinGame");
    }

    function startGame() external onlyOwner {
        console.log("startGame");
    }

    function drawNumber() external onlyOwner {
        console.log("drawNumber");
    }

    function claimBingo() external {
        console.log("claimBingo");
    }
}
