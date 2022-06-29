// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "hardhat/console.sol";

import "contracts/IBingoBoardNFT.sol";
import "contracts/BingoBoardData.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract BingoBoardNFT is
    BingoBoardData,
    ERC721,
    ERC721Enumerable,
    Ownable,
    IBingoBoardNFT
{
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    event BingoBoardNFTMinted(uint256 indexed gameUUID, address indexed to, uint256 indexed tokenId);

    // Mapping from token ID to PlayerBoard
    mapping(uint256 => PlayerBoard) private _playerBoards;

    constructor() ERC721("BingoBoardNFT", "BINGOBOARD") {}

    // -------------------------------------------------------------
    function safeMint(address to, uint256 gameUUID)
        public
        onlyOwner
        returns (uint256)
    {
        console.log("safeMint");
        uint256 tokenId = _tokenIdCounter.current();
        _safeMint(to, tokenId);
        _tokenIdCounter.increment();
        
        // Now generate a board, and tie it to the tokenId
        generateBoard(tokenId, _playerBoards[tokenId], gameUUID);

        emit BingoBoardNFTMinted(gameUUID, to, tokenId);
        
        return tokenId;
    }

    // -------------------------------------------------------------
    function isNFTInGame(uint256 tokenId, uint256 gameUUID)
        public
        view
        returns (bool)
    {
        return _playerBoards[tokenId].data.gameUUID == gameUUID;
    }

    // -------------------------------------------------------------
    function getPlayerBoardData(uint256 tokenId)
        public
        view
        returns (PlayerBoardData memory pbData)
    {
        return _playerBoards[tokenId].data;
    }

    // -------------------------------------------------------------
    function getPlayerBoardsData()
        external
        view
        returns (PlayerBoardData[] memory pbData)
    {
        uint256 numNFTs = ERC721.balanceOf(msg.sender);
        pbData = new PlayerBoardData[](numNFTs);

        for (uint256 i = 0; i < numNFTs; i++) {
            pbData[i] = _playerBoards[tokenOfOwnerByIndex(msg.sender, i)].data;
        }
    }

    // -------------------------------------------------------------
    function getOwnedTokenIDs()
        external
        view
        returns (uint256[] memory pbData)
    {
        uint256 numNFTs = ERC721.balanceOf(msg.sender);
        pbData = new uint256[](numNFTs);

        for(uint i = 0; i < numNFTs; i++) {
            pbData[i] = tokenOfOwnerByIndex(msg.sender, i);
        }
    }

    // -------------------------------------------------------------
    function getBoardAsString(uint256 tokenId)
        external
        view
        returns (string memory boardStr)
    {
        console.log("getBoardAsString()");
        require(_exists(tokenId), "getBoardAsString: nonexistent token");
        boardStr = _playerBoards[tokenId].boardStr;
        console.log(boardStr);
    }

    // -------------------------------------------------------------
    // The following functions are overrides required by Solidity.
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    // -------------------------------------------------------------
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
