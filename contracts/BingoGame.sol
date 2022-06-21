// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "hardhat/console.sol";

import "contracts/IBingoGame.sol";
import "contracts/IBingoSBT.sol";
import "contracts/BingoBoardNFT.sol";
import "contracts/LibSimpleRNG.sol";
import "contracts/utils/EnumerableByteSet.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

uint8 constant MIN_DRAWING_NUM = 1;
uint8 constant MAX_DRAWING_NUM = 75;
uint256 constant BINGO_TIE_INTERVAL_SEC = 2; //60 * 3; // We allows a 3 minute window for ties

contract BingoGame is Initializable, IBingoGame {
    using EnumerableByteSet for EnumerableByteSet.Uint8Set;
    using LibSimpleRNG for LibSimpleRNG.SimpleRNGSeed;

    struct PlayerState {
        bool hasWinnerBeenPaid;
        uint256 numWinningBoards;
    }

    uint256 public drawTimeIntervalSec;
    BingoBoardNFT public bingoBoardNFT;
    IBingoSBT public bingoSBT;

    EnumerableByteSet.Uint8Set private drawnNumbers;
    LibSimpleRNG.SimpleRNGSeed private simpleRNGSeed;
    mapping(address => PlayerState) private winners;
    uint256 private totalPlayerBoardsWon;
    uint256 private weiPerWinningBoard;
    mapping(uint256 => bool) private hasBoardWon;
    uint256 private lastDrawTimeStamp;
    uint256 private firstBingoTimeStamp;
    uint256 private gameUUID;
    bool private _isInitialized;

    modifier isInitialized() {
        require(_isInitialized, "BingoGame Clone must be initialized");
        _;
    }

    // -------------------------------------------------------------
    constructor(BingoBoardNFT bingoBoardNFT_, IBingoSBT bingoSBT_) {
        bingoBoardNFT = bingoBoardNFT_;
        bingoSBT = bingoSBT_;
    }

    // -------------------------------------------------------------
    function init(
        address bingoBoardNFT_,
        address bingoSBT_,
        uint256 gameUUID_,
        uint256 drawTimeIntervalSec_
    ) public payable initializer {
        console.log(
            "BingoGame(%s) init CALLED, msg.value(%s)",
            address(this),
            msg.value
        );
        simpleRNGSeed.incrementRNG = block.timestamp;
        bingoBoardNFT = BingoBoardNFT(bingoBoardNFT_);
        bingoSBT = IBingoSBT(bingoSBT_);
        gameUUID = gameUUID_;
        drawTimeIntervalSec = drawTimeIntervalSec_;
        _isInitialized = true;
    }

    // -------------------------------------------------------------
    function drawNumber() external isInitialized {
        console.log("drawNumber(%s) @ %s", drawnNumbers.length() + 1, address(this));
        require(
            totalPlayerBoardsWon == 0,
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
        returns (bool isBingo)
    {
        console.log("claimBingo()");
        // console.log("bingoBoardNFT address %s", address(bingoBoardNFT));
        console.log("Owner NFT: %s === msg.sender : %s", bingoBoardNFT.ownerOf(tokenId), msg.sender);
        require(
            !hasBoardWon[tokenId],
            "Cannot claim bingo for multiple boards"
        );
        require(
            bingoBoardNFT.ownerOf(tokenId) == msg.sender,
            "Only the board owner can use this tokenId"
        );
        require(
            bingoBoardNFT.isNFTInGame(tokenId, gameUUID),
            "Can only claim Bingo on this games cards"
        );
        // if claimBingo window is expired, revert
        require(
            totalPlayerBoardsWon == 0 ||
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

            winners[msg.sender].numWinningBoards++;
            totalPlayerBoardsWon++;

            // TODO: Come back and fix this
            // FALSE ASSUMPTION: Clone delegatecalls to claimBingo(), and bingoSBT.issue()
            //             is a normal call. So, the owner can be BingoGame implementation contract
            // TODO: Add URI as SVG
            // bingoSBT.mint(msg.sender, "");

            emit BingoClaimed(gameUUID, msg.sender);
            console.log("Total Winners Signed up: %s", totalPlayerBoardsWon);
        }
    }

    // -------------------------------------------------------------
    function getWinnings() external {
        console.log("getWinnings()");
        console.log("Claimer of winnings: %s", msg.sender);
        // require(
        //     block.timestamp > firstBingoTimeStamp + BINGO_TIE_INTERVAL_SEC,
        //     "Bingo Tie Interval must be expired"
        // );
        require(
            winners[msg.sender].numWinningBoards > 0,
            "Only winners can getWinnings()"
        );
        require(
            !winners[msg.sender].hasWinnerBeenPaid,
            "Winner can not be paid twice"
        );

        // Update weiPerWinningBoard once when tie interval is expired
        if (weiPerWinningBoard == 0) {
            weiPerWinningBoard = address(this).balance / totalPlayerBoardsWon;
        }

        uint256 winnerPayout = winners[msg.sender].numWinningBoards *
            weiPerWinningBoard;

        // Handle rounding errors by always taking the minimum
        uint256 weiPayout = winnerPayout < address(this).balance
            ? winnerPayout
            : address(this).balance;

        (bool success, ) = msg.sender.call{value: weiPayout}("");
        require(success, "Payment to winner failed");

        winners[msg.sender].hasWinnerBeenPaid = true;

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
