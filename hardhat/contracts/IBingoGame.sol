// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IBingoGame {
    function init(
        address bingoBoardNFT_,
        address bingoSBT_,
        uint256 gameUUID,
        uint256 drawTimeIntervalSec
    ) external payable;

    function drawNumber() external;

    function claimBingo(uint256 tokenId) external returns (bool isBingo);

    function getDrawnNumbers() external view returns (uint8[] memory);
}
