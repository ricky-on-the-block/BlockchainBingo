// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "hardhat/console.sol";

import "contracts/IBingo.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Bingo is IBingo, Ownable {
    using Strings for uint256;

    enum GameState {
        AwaitingPlayers,
        Running,
        Won
    }
    GameState private gameState = GameState.AwaitingPlayers;

    struct BoardGeneration {
        bool isInitialized;
        mapping(uint8 => bool) numUsed;
    }

    // TODO: Serialize the board, hash it, and check collisions during generation
    struct PlayerBoard {
        BoardGeneration gen;
        uint8[5] bColumn;
        uint8[5] iColumn;
        uint8[5] nColumn; // element 2 is the "free" element
        uint8[5] gColumn;
        uint8[5] oColumn;
        string boardStr;
    }

    mapping(address => PlayerBoard) private playerGameBoards;
    uint8[] public drawnNumbers;
    mapping(uint8 => bool) public numDrawn;

    // Per the Standard US Bingo Rules
    uint8 constant B_OFFSET = 0 * 15;
    uint8 constant I_OFFSET = 1 * 15;
    uint8 constant N_OFFSET = 2 * 15;
    uint8 constant G_OFFSET = 3 * 15;
    uint8 constant O_OFFSET = 4 * 15;
    uint8 constant MIN_DRAWING_NUM = 1;
    uint8 constant MAX_DRAWING_NUM = 75;

    uint256 public constant WEI_BUY_IN = 10 wei;

    // Seed with an input that depends on deployment time
    uint256 private incrementRNG = block.timestamp;

    modifier onlyPlayers() {
        require(
            playerGameBoards[msg.sender].gen.isInitialized,
            "Player must have a board to call this function"
        );
        _;
    }

    modifier inGameState(GameState _gameState) {
        require(
            gameState == _gameState,
            "This function can not be called in this game state"
        );
        _;
    }

    // CREATE A RANDOM NUMBER - GENERATE FUNCTION
    // -------------------------------------------------------------
    // Generate a random number (Can be replaced by Chainlink)
    function rng() private returns (uint256) {
        uint256 rn = uint256(keccak256(abi.encodePacked(incrementRNG)));

        // Increment unchecked to allow wrapping
        unchecked {
            incrementRNG++;
        }

        return rn;
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
        uint8[5] storage boardColumn
    ) private view returns (string memory) {
        string memory elemStr;
        for (uint256 i = 0; i < boardColumn.length; i++) {
            // We know that only the middle element of the board will be 0, so we can check that
            // as the condition
            elemStr = boardColumn[i] == 0 ? "--" : boardColumn[i] <= 9
                ? append(" ", uint256(boardColumn[i]).toString())
                : uint256(boardColumn[i]).toString();

            boardStr = append(boardStr, elemStr, "  ");
        }
        return append(boardStr, "\n");
    }

    // -------------------------------------------------------------
    function generateBoardStr() private view returns (string memory boardStr) {
        console.log("generateBoardStr()");

        PlayerBoard storage gb = playerGameBoards[msg.sender];
        boardStr = concatenateBoardStr(boardStr, gb.bColumn);
        boardStr = concatenateBoardStr(boardStr, gb.iColumn);
        boardStr = concatenateBoardStr(boardStr, gb.nColumn);
        boardStr = concatenateBoardStr(boardStr, gb.gColumn);
        boardStr = concatenateBoardStr(boardStr, gb.oColumn);

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
    function generateBoard(PlayerBoard storage self) private {
        console.log("generateBoard()");

        generateColumn(self, self.bColumn, B_OFFSET);
        generateColumn(self, self.iColumn, I_OFFSET);
        generateColumn(self, self.nColumn, N_OFFSET);
        generateColumn(self, self.gColumn, G_OFFSET);
        generateColumn(self, self.oColumn, O_OFFSET);

        // Manually set N[2] => 0, because it is unused
        self.nColumn[2] = 0;
        self.gen.isInitialized = true;
    }

    // -------------------------------------------------------------
    function joinGame()
        external
        payable
        inGameState(GameState.AwaitingPlayers)
    {
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
    function startGame()
        external
        onlyOwner
        inGameState(GameState.AwaitingPlayers)
    {
        console.log("startGame()");

        // Mark 0 as drawn for N2 efficient lookups during `claimBingo`
        // Every player board has N2 set to 0 manually during generateBoard()
        // No other board element can be set to 0, due to range-bounding the RNG
        numDrawn[0] = true;
        gameState = GameState.Running;

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
        boardStr = playerGameBoards[msg.sender].boardStr;
        console.log(boardStr);
    }

    // -------------------------------------------------------------
    function drawNumber() external onlyOwner inGameState(GameState.Running) {
        console.log("drawNumber()");
        uint8 randomNum;

        // Loop the rng until we find a number that we haven't already drawn
        do {
            // Mod 75 results in a uint in the range [0, 74], so add 1 to get to range [1, 75]
            randomNum = uint8(((rng() % MAX_DRAWING_NUM) + 1));
        } while (numDrawn[randomNum]);

        require(
            randomNum >= MIN_DRAWING_NUM && randomNum <= MAX_DRAWING_NUM,
            "drawNumber() drew number outside valid range"
        );

        drawnNumbers.push(randomNum);
        numDrawn[randomNum] = true;
        emit NumberDrawn(randomNum);
    }

    // TODO: Make use of WinConditions in `claimBingo` to save gas
    // enum WinCondition {
    //     SequentialRow,
    //     SequentialCol,
    //     SequentialDiag,
    //     FourCorners,
    //     PatternX,
    //     PatternB,
    //     PatternI,
    //     PatternN,
    //     PatternG,
    //     PatternO,
    //     Blackout
    // }

    // -------------------------------------------------------------
    function checkWinCondition5SeqRows(PlayerBoard storage pb)
        private
        view
        returns (bool)
    {
        // Check every row
        for (uint8 i = 0; i < 5; i++) {
            if (
                numDrawn[pb.bColumn[i]] &&
                numDrawn[pb.iColumn[i]] &&
                numDrawn[pb.nColumn[i]] &&
                numDrawn[pb.gColumn[i]] &&
                numDrawn[pb.oColumn[i]]
            ) {
                return true;
            }
        }
        return false;
    }

    // -------------------------------------------------------------
    function checkWinCondition5SeqCol(uint8[5] storage col)
        private
        view
        returns (bool)
    {
        if (
            numDrawn[col[0]] &&
            numDrawn[col[1]] &&
            numDrawn[col[2]] &&
            numDrawn[col[3]] &&
            numDrawn[col[4]]
        ) {
            return true;
        }
        return false;
    }

    // -------------------------------------------------------------
    function checkWinCondition5SeqCols(PlayerBoard storage pb)
        private
        view
        returns (bool)
    {
        if (checkWinCondition5SeqCol(pb.bColumn)) {
            return true;
        }
        if (checkWinCondition5SeqCol(pb.iColumn)) {
            return true;
        }
        if (checkWinCondition5SeqCol(pb.nColumn)) {
            return true;
        }
        if (checkWinCondition5SeqCol(pb.gColumn)) {
            return true;
        }
        if (checkWinCondition5SeqCol(pb.oColumn)) {
            return true;
        }

        return false;
    }

    // -------------------------------------------------------------
    function checkWinCondition5SeqDiag(PlayerBoard storage pb)
        private
        view
        returns (bool)
    {
        // Check negative slope diagonal first
        if (
            numDrawn[pb.bColumn[0]] &&
            numDrawn[pb.iColumn[1]] &&
            numDrawn[pb.nColumn[2]] &&
            numDrawn[pb.gColumn[3]] &&
            numDrawn[pb.oColumn[4]]
        ) {
            return true;
        }

        // Then, check positive slope diagonal
        if (
            numDrawn[pb.bColumn[4]] &&
            numDrawn[pb.iColumn[3]] &&
            numDrawn[pb.nColumn[2]] &&
            numDrawn[pb.gColumn[1]] &&
            numDrawn[pb.oColumn[0]]
        ) {
            return true;
        }

        return false;
    }

    // -------------------------------------------------------------
    function claimBingo()
        external
        onlyPlayers
        inGameState(GameState.Running)
        returns (bool isBingo)
    {
        console.log("claimBingo()");
        PlayerBoard storage pb = playerGameBoards[msg.sender];

        // Boolean short-circuit eval should save on gas with the earliest win condition
        if (
            checkWinCondition5SeqRows(pb) ||
            checkWinCondition5SeqCols(pb) ||
            checkWinCondition5SeqDiag(pb)
        ) {
            isBingo = true;
            uint256 awardAmount = address(this).balance;

            // Transfer winnings and announce the game has been won
            payable(msg.sender).transfer(awardAmount);
            emit GameWon(block.timestamp, msg.sender, awardAmount);

            gameState = GameState.Won;
        }

        return isBingo;
    }
}
