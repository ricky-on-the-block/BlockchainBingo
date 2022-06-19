// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "contracts/BingoBoardData.sol";

interface IBingoBoardNFT {
    function safeMint(address to, uint256 gameUUID) external returns (uint256);

    function isNFTInGame(uint256 tokenId, uint256 gameUUID)
        external
        view
        returns (bool);

    function getPlayerBoardData(uint256 tokenId)
        external
        view
        returns (BingoBoardData.PlayerBoardData memory pbData);

    function getPlayerBoardsData()
        external
        view
        returns (BingoBoardData.PlayerBoardData[] memory pbData);

    function getBoardAsString(uint256 tokenId)
        external
        view
        returns (string memory boardStr);
}
