// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "hardhat/console.sol";

import "contracts/IBingo.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// uint8 constant B_MIN_VALUE = 1;
// uint8 constant B_MAX_VALUE = 15;
// uint8 constant I_MIN_VALUE = 16;
// uint8 constant I_MAX_VALUE = 30;
// uint8 constant N_MIN_VALUE = 31;
// uint8 constant N_MAX_VALUE = 45;
// uint8 constant G_MIN_VALUE = 46;
// uint8 constant G_MAX_VALUE = 60;
// uint8 constant O_MIN_VALUE = 61;
// uint8 constant O_MAX_VALUE = 75;

contract Bingo is IBingo, Ownable {
    // Long-term: move this to NFT generation. For now, a double mapping works
    struct BoardElement {
        uint8 value;
        bool  hasBeenDrawn;
    }

    struct BoardGeneration {
        bool                   isInitialized;
        mapping(uint8 => bool) hasNumBeenUsed;
    }

    struct PlayerBoard {
        BoardGeneration gen;
        BoardElement[5] bColumn;
        BoardElement[5] iColumn;
        BoardElement[5] nColumn;    // element 2 is the "free" element
        BoardElement[5] gColumn;
        BoardElement[5] oColumn;
    }

    mapping(address => PlayerBoard) private playerGameBoards;
    uint8[] public drawnNumbers;

    // What are the large operations I must do?
    // 1. Generate the board according to bingo rules (number ranges for each column)
    // 2. On claimBingo, efficiently check the player board for the win condition

    // Per the Standard US Bingo Rules
    uint8 constant B_OFFSET = 0 * 15;
    uint8 constant I_OFFSET = 1 * 15;
    uint8 constant N_OFFSET = 2 * 15;
    uint8 constant G_OFFSET = 3 * 15;
    uint8 constant O_OFFSET = 4 * 15;
    // Upper Bound for Drawing Number
    uint8 constant MAX_DRAWING_NUM = 75;

    uint constant public WEI_BUY_IN = 10 wei;

    uint private incrementRN = 0;

    modifier onlyPlayers() {
        require(
            playerGameBoards[msg.sender].gen.isInitialized, "Player must have a board to call this function");
        _;
    }

    // CREATE A RANDOM NUMBER - GENERATE FUNCTION
    // -------------------------------------------------------------
    // Generate a random number (Can be replaced by Chainlink)
    function rng() private returns(uint){
        return uint(keccak256(abi.encodePacked(incrementRN++)));
    }

    // RANDOMLY GENERATE A SINGLE COLUMN OF THE PLAYER BOARD
    // -------------------------------------------------------------
    function generateColumn(
        PlayerBoard storage self,
        BoardElement[5] storage column,
        uint8 columnOffset)
        private
    {
        console.log("generateColumn()");

        uint8 randomNum;
        for(uint i = 0; i < column.length;) {
            // Mod 15 results in a uint in the range [0, 14], so add 1 to get to range [1, 15]
            // Then, multiply by the offset for the desired column
            randomNum = uint8((rng() % 15) + 1 + columnOffset);

            // Only increment when we find a non-colliding random number for the current column
            if(randomNum != 0 && !self.gen.hasNumBeenUsed[randomNum]) {
                console.log(randomNum);

                column[i].value = randomNum;
                self.gen.hasNumBeenUsed[randomNum] = true;

                // Manual increment
                i++;
            }
        }
    }

    // RANDOMLY GENERATE THE PLAYER BOARD
    // -------------------------------------------------------------
    function generateBoard(PlayerBoard storage self) private {
        console.log("generateBoard()");

        generateColumn(self, self.bColumn, B_OFFSET);
        generateColumn(self, self.iColumn, I_OFFSET);
        generateColumn(self, self.nColumn, N_OFFSET);
        generateColumn(self, self.gColumn, G_OFFSET);
        generateColumn(self, self.oColumn, O_OFFSET);

        // Manually set N[2] => 0, because it is unused
        self.nColumn[2].value = 0;
        self.gen.isInitialized = true;
    }

    function joinGame() external payable {
        console.log("joinGame()");

        require(msg.value >= WEI_BUY_IN, "Player has not met the minimum buy in");
        require(!playerGameBoards[msg.sender].gen.isInitialized, "Player has already joined the game");

        generateBoard(playerGameBoards[msg.sender]);

        emit GameJoined(msg.sender);
    }

    function startGame() external onlyOwner {
        console.log("startGame()");
        emit GameStarted(block.timestamp);
    }

    function getBoard() external onlyPlayers returns(string memory boardStr) {
        console.log("getBoard()");
        return "this is a board";
    }

    function drawNumber() external onlyOwner {
        console.log("drawNumber()");

        // Mod 75 results in a uint in the range [0, 74], so add 1 to get to range [1, 75]
        uint8 randomNum = uint8(((rng() % MAX_DRAWING_NUM) + 1));
        drawnNumbers.push(randomNum);

        emit NumberDrawn(randomNum);
    }

    function claimBingo() external onlyPlayers {
        console.log("claimBingo()");
    }

}
