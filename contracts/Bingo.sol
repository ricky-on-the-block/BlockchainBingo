// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "hardhat/console.sol";

import "contracts/IBingo.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Bingo is IBingo, Ownable {
    using Strings for uint256;

    struct BoardElement {
        uint8 value;
        bool hasBeenDrawn;
    }

    struct BoardGeneration {
        bool isInitialized;
        mapping(uint8 => bool) hasNumBeenUsed;
    }

    // TODO: Serialize the board, hash it, and check collisions during generation
    struct PlayerBoard {
        BoardGeneration gen;
        BoardElement[5] bColumn;
        BoardElement[5] iColumn;
        BoardElement[5] nColumn; // element 2 is the "free" element
        BoardElement[5] gColumn;
        BoardElement[5] oColumn;
        string          boardStr;
    }

    mapping(address => PlayerBoard) private playerGameBoards;
    uint8[] public drawnNumbers;

    // Per the Standard US Bingo Rules
    uint8 constant B_OFFSET = 0 * 15;
    uint8 constant I_OFFSET = 1 * 15;
    uint8 constant N_OFFSET = 2 * 15;
    uint8 constant G_OFFSET = 3 * 15;
    uint8 constant O_OFFSET = 4 * 15;
    uint8 constant MAX_DRAWING_NUM = 75;

    uint256 public constant WEI_BUY_IN = 10 wei;

    uint256 private incrementRN = 0;

    modifier onlyPlayers() {
        require(
            playerGameBoards[msg.sender].gen.isInitialized,
            "Player must have a board to call this function"
        );
        _;
    }

    // CREATE A RANDOM NUMBER - GENERATE FUNCTION
    // -------------------------------------------------------------
    // Generate a random number (Can be replaced by Chainlink)
    function rng() private returns (uint256) {
        return uint256(keccak256(abi.encodePacked(incrementRN++)));
    }

    // -------------------------------------------------------------
    function append(string memory a, string memory b)
        internal
        pure
        returns (string memory)
    {
        return string(abi.encodePacked(a, b));
    }

    // -------------------------------------------------------------
    function append(
        string memory a,
        string memory b,
        string memory c
    ) internal pure returns (string memory) {
        return string(abi.encodePacked(a, b, c));
    }

    // -------------------------------------------------------------
    function concatenateBoardStr(
        string memory boardStr,
        BoardElement[5] storage boardColumn
    ) private view returns (string memory) {
        string memory elemStr;
        for (uint256 i = 0; i < boardColumn.length; i++) {
            // We know that only the middle element of the board will be 0, so we can check that
            // as the condition
            elemStr = boardColumn[i].value == 0
                ? "--"
                : boardColumn[i].value <= 9
                ? append(" ", uint256(boardColumn[i].value).toString())
                : uint256(boardColumn[i].value).toString();

            boardStr = append(boardStr, elemStr, "  ");
        }
        return append(boardStr, "\n");
    }

    // -------------------------------------------------------------
    function generateBoardStr()
        private
        view
        returns (string memory boardStr)
    {
        console.log("getBoard()");

        PlayerBoard storage gb = playerGameBoards[msg.sender];
        boardStr = concatenateBoardStr(boardStr, gb.bColumn);
        boardStr = concatenateBoardStr(boardStr, gb.iColumn);
        boardStr = concatenateBoardStr(boardStr, gb.nColumn);
        boardStr = concatenateBoardStr(boardStr, gb.gColumn);
        boardStr = concatenateBoardStr(boardStr, gb.oColumn);

        console.log(boardStr);
        return boardStr;
    }

    // RANDOMLY GENERATE A SINGLE COLUMN OF THE PLAYER BOARD
    // -------------------------------------------------------------
    function generateColumn(
        PlayerBoard storage self,
        BoardElement[5] storage column,
        uint8 columnOffset
    ) private {
        console.log("generateColumn()");

        uint8 randomNum;
        for (uint256 i = 0; i < column.length; ) {
            // Mod 15 results in a uint in the range [0, 14], so add 1 to get to range [1, 15]
            // Then, multiply by the offset for the desired column
            randomNum = uint8((rng() % 15) + 1 + columnOffset);

            // Only increment when we find a non-colliding random number for the current column
            if (randomNum != 0 && !self.gen.hasNumBeenUsed[randomNum]) {
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

    // -------------------------------------------------------------
    function joinGame() external payable {
        console.log("joinGame()");

        require(
            msg.value >= WEI_BUY_IN,
            "Player has not met the minimum buy in"
        );
        require(
            !playerGameBoards[msg.sender].gen.isInitialized,
            "Player has already joined the game"
        );

        generateBoard(playerGameBoards[msg.sender]);

        // TODO: Revisit error conditions here
        playerGameBoards[msg.sender].boardStr = generateBoardStr();

        emit GameJoined(msg.sender, playerGameBoards[msg.sender].boardStr);
    }

    // -------------------------------------------------------------
    function startGame() external onlyOwner {
        console.log("startGame()");
        emit GameStarted(block.timestamp);
    }

    // -------------------------------------------------------------
    function getBoard()
        public
        view
        onlyPlayers
        returns (string memory boardStr)
    {
        console.log("getBoard()");
        return playerGameBoards[msg.sender].boardStr;
    }

    // -------------------------------------------------------------
    function drawNumber() external onlyOwner {
        console.log("drawNumber()");

        // Mod 75 results in a uint in the range [0, 74], so add 1 to get to range [1, 75]
        uint8 randomNum = uint8(((rng() % MAX_DRAWING_NUM) + 1));
        drawnNumbers.push(randomNum);

        emit NumberDrawn(randomNum);
    }
    
    // check every win condition pattern
    // x, b, i, n, g, o, row, column, diagonal

    // -------------------------------------------------------------
    function claimBingo() external onlyPlayers {
        console.log("claimBingo()");
    }
}
