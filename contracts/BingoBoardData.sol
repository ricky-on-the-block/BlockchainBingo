// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "hardhat/console.sol";

import "contracts/SimpleRNG.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract BingoBoardData is SimpleRNG {
    struct BoardGeneration {
        bool isInitialized;
        mapping(uint8 => bool) numUsed;
    }

    struct PlayerBoardData {
        uint256 gameUUID;
        uint8[5] bColumn;
        uint8[5] iColumn;
        uint8[5] nColumn; // element 2 is the "free" element
        uint8[5] gColumn;
        uint8[5] oColumn;
    }

    struct PlayerBoard {
        BoardGeneration gen;
        PlayerBoardData data;
        string boardStr;
    }

    // Per the Standard US Bingo Rules
    uint8 constant B_OFFSET = 0 * 15;
    uint8 constant I_OFFSET = 1 * 15;
    uint8 constant N_OFFSET = 2 * 15;
    uint8 constant G_OFFSET = 3 * 15;
    uint8 constant O_OFFSET = 4 * 15;

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
        uint8[5] storage boardColumn
    ) private view returns (string memory) {
        string memory elemStr;
        for (uint256 i = 0; i < boardColumn.length; i++) {
            // We know that only the middle element of the board will be 0, so we can check that
            // as the condition
            elemStr = boardColumn[i] == 0 ? "--" : boardColumn[i] <= 9
                ? append(" ", Strings.toString(uint256(boardColumn[i])))
                : Strings.toString(uint256(boardColumn[i]));

            boardStr = append(boardStr, elemStr, "  ");
        }
        return append(boardStr, "\n");
    }

    // -------------------------------------------------------------
    function generateBoardStr(PlayerBoard storage self)
        private
        view
        returns (string memory boardStr)
    {
        console.log("generateBoardStr()");

        boardStr = concatenateBoardStr(boardStr, self.data.bColumn);
        boardStr = concatenateBoardStr(boardStr, self.data.iColumn);
        boardStr = concatenateBoardStr(boardStr, self.data.nColumn);
        boardStr = concatenateBoardStr(boardStr, self.data.gColumn);
        boardStr = concatenateBoardStr(boardStr, self.data.oColumn);

        return boardStr;
    }

    // RANDOMLY GENERATE A SINGLE COLUMN OF THE PLAYER BOARD
    // -------------------------------------------------------------
    function generateColumn(
        PlayerBoard storage self,
        uint8[5] storage column,
        uint8 columnOffset
    ) private {
        console.log("generateColumn()");

        uint8 randomNum;
        for (uint256 i = 0; i < column.length; ) {
            // Mod 15 results in a uint in the range [0, 14], so add 1 to get to range [1, 15]
            // Then, multiply by the offset for the desired column
            randomNum = uint8((rng() % 15) + 1 + columnOffset);

            // Only increment when we find a non-colliding random number for the current column
            if (randomNum != 0 && !self.gen.numUsed[randomNum]) {
                column[i] = randomNum;
                self.gen.numUsed[randomNum] = true;

                // Manual increment
                i++;
            }
        }
    }

    // RANDOMLY GENERATE THE PLAYER BOARD
    // -------------------------------------------------------------
    function generateBoard(PlayerBoard storage self, uint256 gameUUID)
        internal
    {
        console.log("generateBoard()");

        self.data.gameUUID = gameUUID;

        generateColumn(self, self.data.bColumn, B_OFFSET);
        generateColumn(self, self.data.iColumn, I_OFFSET);
        generateColumn(self, self.data.nColumn, N_OFFSET);
        generateColumn(self, self.data.gColumn, G_OFFSET);
        generateColumn(self, self.data.oColumn, O_OFFSET);

        // Manually set N[2] => 0, because it is unused
        self.data.nColumn[2] = 0;
        self.gen.isInitialized = true;

        // Now generate the game board string, and save it
        self.boardStr = generateBoardStr(self);
    }
}
