// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "hardhat/console.sol";

import "contracts/IBingo.sol";
import "contracts/BingoBoardNFT.sol";

contract BingoGame is IBingo, BingoBoardNFT {
    enum GameState {
        AwaitingPlayers,
        Running,
        Won
    }
    GameState private gameState = GameState.AwaitingPlayers;

    uint8[] private drawnNumbers;
    mapping(uint8 => bool) private numDrawn;
    uint8 constant MIN_DRAWING_NUM = 1;
    uint8 constant MAX_DRAWING_NUM = 75;

    uint256 public constant WEI_BUY_IN = 10 wei;

    modifier onlyPlayers() {
        require(
            balanceOf(msg.sender) >= 1,
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
            balanceOf(msg.sender) == 0,
            "Player has already joined the game"
        );

        uint256 mintedTokenId = safeMint(msg.sender);
        emit GameJoined(msg.sender, getBoardAsString(mintedTokenId));
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
    function claimBingo(uint256 tokenId)
        external
        onlyPlayers
        inGameState(GameState.Running)
        returns (bool isBingo)
    {
        console.log("claimBingo()");
        PlayerBoard storage pb = _playerBoards[tokenId];

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
