// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "hardhat/console.sol";

import "contracts/IBingoGame.sol";
import "contracts/BingoBoardNFT.sol";
import "contracts/utils/EnumerableByteSet.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

uint8 constant MIN_DRAWING_NUM = 1;
uint8 constant MAX_DRAWING_NUM = 75;

contract BingoGame is Ownable, BingoBoardNFT, IBingoGame {
    using EnumerableByteSet for EnumerableByteSet.Uint8Set;
    EnumerableByteSet.Uint8Set private drawnNumbers;

    uint256 public drawTimeIntervalSec = 30;
    uint256 private lastDrawTimeStamp;

    // TO DO: attach the balance of the owner to the GameUUID
    modifier onlyPlayers() {
        require(
            balanceOf(msg.sender) >= 1,
            "Player must have a board to call this function"
        );
        _;
    }

    // -------------------------------------------------------------
    function init(uint256 timeIntervalSec) onlyOwner public {
        drawTimeIntervalSec = timeIntervalSec;
    }

    // -------------------------------------------------------------
    function drawNumber() external {
        console.log("drawNumber()");
        require(block.timestamp >= lastDrawTimeStamp + drawTimeIntervalSec, "Not ready to draw a number yet");
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
        onlyPlayers
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
        }

        return isBingo;
    }

    // -------------------------------------------------------------
    function getDrawnNumbers() external view returns (uint8[] memory) {
        return drawnNumbers.values();
    }

    // -------------------------------------------------------------
    function checkWinCondition5SeqRows(PlayerBoard storage pb)
        private
        view
        returns (bool)
    {
        // Check every row
        for (uint8 i = 0; i < 5; i++) {
            if (
                drawnNumbers.contains(pb.bColumn[i]) &&
                drawnNumbers.contains(pb.iColumn[i]) &&
                drawnNumbers.contains(pb.nColumn[i]) &&
                drawnNumbers.contains(pb.gColumn[i]) &&
                drawnNumbers.contains(pb.oColumn[i])
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
            drawnNumbers.contains(pb.bColumn[0]) &&
            drawnNumbers.contains(pb.iColumn[1]) &&
            drawnNumbers.contains(pb.nColumn[2]) &&
            drawnNumbers.contains(pb.gColumn[3]) &&
            drawnNumbers.contains(pb.oColumn[4])
        ) {
            return true;
        }

        // Then, check positive slope diagonal
        if (
            drawnNumbers.contains(pb.bColumn[4]) &&
            drawnNumbers.contains(pb.iColumn[3]) &&
            drawnNumbers.contains(pb.nColumn[2]) &&
            drawnNumbers.contains(pb.gColumn[1]) &&
            drawnNumbers.contains(pb.oColumn[0])
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
