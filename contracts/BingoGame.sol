// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "hardhat/console.sol";

import "contracts/IBingoGame.sol";
import "contracts/IBingoBoardNFT.sol";
import "contracts/IBingoSBT.sol";
import "contracts/BingoBoardNFT.sol";
import "contracts/LibSimpleRNG.sol";
import "contracts/utils/EnumerableByteSet.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

uint8 constant MIN_DRAWING_NUM = 1;
uint8 constant MAX_DRAWING_NUM = 75;
uint256 constant BINGO_TIE_INTERVAL_SEC = 60 * 3; // We allows a 3 minute window for ties

contract BingoGame is Initializable, IBingoGame {
    using EnumerableByteSet for EnumerableByteSet.Uint8Set;
    EnumerableByteSet.Uint8Set private drawnNumbers;

    using LibSimpleRNG for LibSimpleRNG.SimpleRNGSeed;
    LibSimpleRNG.SimpleRNGSeed private simpleRNGSeed;

    uint256 public drawTimeIntervalSec;
    uint256 private lastDrawTimeStamp;
    uint256 private firstBingoTimeStamp;
    uint256 private gameUUID;
    bool private _isInitialized;
    address[] private players;
    address[] private winners;
    mapping(address => bool) hasWinnerBeenPaid;
    uint256 private weiPerWinner;
    IBingoBoardNFT public bingoBoardNFT;
    IBingoSBT public bingoSBT;

    modifier onlyAddresses(address[] storage addressArr) {
        bool isPlayer;

        for (uint256 i = 0; i < addressArr.length; i++) {
            if (addressArr[i] == msg.sender) {
                isPlayer = true;
            }
        }

        require(isPlayer, "Function for valid addresses only");
        _;
    }

    modifier isInitialized() {
        require(_isInitialized, "BingoGame Clone must be initialized");
        _;
    }

    // -------------------------------------------------------------
    constructor(IBingoBoardNFT bingoBoardNFT_, IBingoSBT bingoSBT_) {
        bingoBoardNFT = bingoBoardNFT_;
        bingoSBT = bingoSBT_;
    }

    // -------------------------------------------------------------
    function init(
        address bingoBoardNFT_,
        address bingoSBT_,
        uint256 gameUUID_,
        uint256 drawTimeIntervalSec_,
        address[] calldata players_
    ) public payable initializer {
        console.log(
            "BingoGame(%s) init CALLED, msg.value(%s)",
            address(this),
            msg.value
        );
        simpleRNGSeed.incrementRNG = block.timestamp;
        bingoBoardNFT = IBingoBoardNFT(bingoBoardNFT_);
        bingoSBT = IBingoSBT(bingoSBT_);
        gameUUID = gameUUID_;
        drawTimeIntervalSec = drawTimeIntervalSec_;
        players = players_;
        _isInitialized = true;
    }

    // -------------------------------------------------------------
    function drawNumber() external isInitialized {
        console.log("drawNumber() @ %s", address(this));
        require(
            winners.length == 0,
            "Can only drawNumber when there are no winners"
        );
        require(
            block.timestamp >= lastDrawTimeStamp + drawTimeIntervalSec,
            "Not ready to draw a number yet"
        );
        require(
            drawnNumbers.length() < MAX_DRAWING_NUM,
            "No more valid numbers to draw"
        );
        uint8 randomNum;

        // Loop the rng until we find a number that we haven't already drawn
        do {
            // Mod 75 results in a uint in the range [0, 74], so add 1 to get to range [1, 75]
            randomNum = uint8(((simpleRNGSeed.rng() % MAX_DRAWING_NUM) + 1));
        } while (drawnNumbers.contains(randomNum));

        require(
            randomNum >= MIN_DRAWING_NUM && randomNum <= MAX_DRAWING_NUM,
            "drawNumber() drew number outside valid range"
        );

        drawnNumbers.add(randomNum);
        emit NumberDrawn(gameUUID, randomNum);
        lastDrawTimeStamp = block.timestamp;
    }

    // -------------------------------------------------------------
    function claimBingo(uint256 tokenId)
        external
        isInitialized
        onlyAddresses(players)
        returns (bool isBingo)
    {
        console.log("claimBingo()");
        console.log("bingoBoardNFT address %s", address(bingoBoardNFT));
        require(
            bingoBoardNFT.isNFTInGame(tokenId, gameUUID),
            "Can only claim Bingo on this games cards"
        );
        // if claimBingo window is expired, revert
        require(
            winners.length == 0 ||
                block.timestamp < firstBingoTimeStamp + BINGO_TIE_INTERVAL_SEC,
            "claimBingo tie interval expired"
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

            // Update timestamp on first bingo winner
            if (firstBingoTimeStamp == 0) {
                firstBingoTimeStamp = block.timestamp;
            }

            winners.push(msg.sender);

            // ASSUMPTION: Clone delegatecalls to claimBingo(), and bingoSBT.issue()
            //             is a normal call. So, the owner can be BingoGame implementation contract
            // TODO: Add URI as SVG
            bingoSBT.mint(msg.sender, "");

            emit BingoClaimed(gameUUID, msg.sender);
        }
    }

    // -------------------------------------------------------------
    function getWinnings() external onlyAddresses(winners) {
        require(
            block.timestamp > firstBingoTimeStamp + BINGO_TIE_INTERVAL_SEC,
            "Bingo Tie Interval must be expired"
        );
        require(!hasWinnerBeenPaid[msg.sender], "Winner can not be paid twice");

        // Update weiPerWinner once when tie interval is expired
        if (weiPerWinner == 0) {
            weiPerWinner = address(this).balance / winners.length;
        }

        // Handle rounding errors by always taking the minimum
        uint256 weiPayout = weiPerWinner < address(this).balance
            ? weiPerWinner
            : address(this).balance;

        (bool success, ) = msg.sender.call{value: weiPayout}("");
        require(success, "Payment to winner failed");

        hasWinnerBeenPaid[msg.sender] = true;

        emit WinningsDistributed(gameUUID, msg.sender, weiPayout);
    }

    // -------------------------------------------------------------
    function getDrawnNumbers()
        external
        view
        isInitialized
        returns (uint8[] memory)
    {
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
