// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "hardhat/console.sol";

import "contracts/IBingoGame.sol";
import "contracts/IBingoBoardNFT.sol";
import "contracts/BingoBoardNFT.sol";
import "contracts/SimpleRNG.sol";
import "contracts/utils/EnumerableByteSet.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

uint8 constant MIN_DRAWING_NUM = 1;
uint8 constant MAX_DRAWING_NUM = 75;

contract BingoGame is Ownable, IBingoGame, SimpleRNG {
    using EnumerableByteSet for EnumerableByteSet.Uint8Set;
    EnumerableByteSet.Uint8Set private drawnNumbers;

    uint256 public drawTimeIntervalSec;
    uint256 private lastDrawTimeStamp;
    uint256 private gameUUID;
    bool private _isInitialized;
    address[] private players;
    IBingoBoardNFT public bingoBoardNFT;

    modifier onlyPlayers() {
        bool isPlayer;

        for (uint256 i = 0; i < players.length; i++) {
            if (players[i] == msg.sender) {
                isPlayer = true;
            }
        }

        require(isPlayer, "Player must have a board to call this function");
        _;
    }

    modifier isInitialized() {
        require(_isInitialized, "BingoGame Clone must be initialized");
        _;
    }

    // -------------------------------------------------------------
    constructor(address bingoBoardNFT_) {
        bingoBoardNFT = IBingoBoardNFT(bingoBoardNFT_);
    }

    // -------------------------------------------------------------
    function init(
        uint256 gameUUID_,
        uint256 drawTimeIntervalSec_,
        address[] calldata players_
    ) public onlyOwner {
        gameUUID = gameUUID_;
        drawTimeIntervalSec = drawTimeIntervalSec_;
        players = players_;
        _isInitialized = true;
    }

    // -------------------------------------------------------------
    function drawNumber() external isInitialized {
        console.log("drawNumber()");
        require(
            block.timestamp >= lastDrawTimeStamp + drawTimeIntervalSec,
            "Not ready to draw a number yet"
        );
        uint8 randomNum;

        // Loop the rng until we find a number that we haven't already drawn
        do {
            // Mod 75 results in a uint in the range [0, 74], so add 1 to get to range [1, 75]
            randomNum = uint8(((rng() % MAX_DRAWING_NUM) + 1));
        } while (drawnNumbers.contains(randomNum));

        require(
            randomNum >= MIN_DRAWING_NUM && randomNum <= MAX_DRAWING_NUM,
            "drawNumber() drew number outside valid range"
        );

        drawnNumbers.add(randomNum);
        emit NumberDrawn(randomNum);
        lastDrawTimeStamp = block.timestamp;
    }

    // -------------------------------------------------------------
    function claimBingo(uint256 tokenId)
        external
        isInitialized
        onlyPlayers
        returns (bool isBingo)
    {
        console.log("claimBingo()");
        require(
            bingoBoardNFT.isNFTInGame(tokenId, gameUUID),
            "Can only claim Bingo on this games cards"
        );

        BingoBoardNFT.PlayerBoardData memory pbData = bingoBoardNFT
            .getPlayerBoardData(tokenId);

        // Boolean short-circuit eval should save on gas with the earliest win condition
        if (
            checkWinCondition5SeqRows(pbData) ||
            checkWinCondition5SeqCols(pbData) ||
            checkWinCondition5SeqDiag(pbData)
        ) {
            isBingo = true;
            uint256 awardAmount = address(this).balance;

            // Transfer winnings and announce the game has been won
            payable(msg.sender).transfer(awardAmount);
            emit GameWon(block.timestamp, msg.sender, awardAmount);

            //Mint BingoSBT to the winner
        }

        return isBingo;
    }

    // -------------------------------------------------------------
    function getDrawnNumbers() external view isInitialized returns (uint8[] memory) {
        return drawnNumbers.values();
    }

    // -------------------------------------------------------------
    function checkWinCondition5SeqRows(
        BingoBoardNFT.PlayerBoardData memory pbData
    ) private view returns (bool) {
        // Check every row
        for (uint8 i = 0; i < 5; i++) {
            if (
                drawnNumbers.contains(pbData.bColumn[i]) &&
                drawnNumbers.contains(pbData.iColumn[i]) &&
                drawnNumbers.contains(pbData.nColumn[i]) &&
                drawnNumbers.contains(pbData.gColumn[i]) &&
                drawnNumbers.contains(pbData.oColumn[i])
            ) {
                return true;
            }
        }
        return false;
    }

    // -------------------------------------------------------------
    function checkWinCondition5SeqCol(uint8[5] memory col)
        private
        view
        returns (bool)
    {
        if (
            drawnNumbers.contains(col[0]) &&
            drawnNumbers.contains(col[1]) &&
            drawnNumbers.contains(col[2]) &&
            drawnNumbers.contains(col[3]) &&
            drawnNumbers.contains(col[4])
        ) {
            return true;
        }
        return false;
    }

    // -------------------------------------------------------------
    function checkWinCondition5SeqCols(
        BingoBoardNFT.PlayerBoardData memory pbData
    ) private view returns (bool) {
        if (checkWinCondition5SeqCol(pbData.bColumn)) {
            return true;
        }
        if (checkWinCondition5SeqCol(pbData.iColumn)) {
            return true;
        }
        if (checkWinCondition5SeqCol(pbData.nColumn)) {
            return true;
        }
        if (checkWinCondition5SeqCol(pbData.gColumn)) {
            return true;
        }
        if (checkWinCondition5SeqCol(pbData.oColumn)) {
            return true;
        }

        return false;
    }

    // -------------------------------------------------------------
    function checkWinCondition5SeqDiag(
        BingoBoardNFT.PlayerBoardData memory pbData
    ) private view returns (bool) {
        // Check negative slope diagonal first
        if (
            drawnNumbers.contains(pbData.bColumn[0]) &&
            drawnNumbers.contains(pbData.iColumn[1]) &&
            drawnNumbers.contains(pbData.nColumn[2]) &&
            drawnNumbers.contains(pbData.gColumn[3]) &&
            drawnNumbers.contains(pbData.oColumn[4])
        ) {
            return true;
        }

        // Then, check positive slope diagonal
        if (
            drawnNumbers.contains(pbData.bColumn[4]) &&
            drawnNumbers.contains(pbData.iColumn[3]) &&
            drawnNumbers.contains(pbData.nColumn[2]) &&
            drawnNumbers.contains(pbData.gColumn[1]) &&
            drawnNumbers.contains(pbData.oColumn[0])
        ) {
            return true;
        }

        return false;
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
}
