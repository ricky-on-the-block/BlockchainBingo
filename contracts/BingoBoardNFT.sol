// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "hardhat/console.sol";

import "contracts/SimpleRNG.sol";
import "contracts/IBingoBoardNFTMintable.sol";
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
    IBingoBoardNFTMintable
{
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    // Mapping from token ID to PlayerBoard
    mapping(uint256 => PlayerBoard) _playerBoards;

    constructor() ERC721("BingoBoardNFT", "BINGOBOARD") {}

    function safeMint(address to, uint256 gameUUID)
        public
        onlyOwner
        returns (uint256)
    {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);

        // Now generate a board, and tie it to the tokenId
        generateBoard(_playerBoards[tokenId], gameUUID);

        return tokenId;
    }

    // -------------------------------------------------------------
    function getBingoBoardsData()
        external
        view
        returns (PlayerBoardData[] memory pbData)
    {
        uint256 numNFTs = ERC721.balanceOf(msg.sender);
        pbData = new PlayerBoardData[](numNFTs);

        for (uint256 i = 0; i < numNFTs; i++) {
            pbData[i] = _playerBoards[tokenByIndex(i)].data;
        }
    }

    // -------------------------------------------------------------
    function getBoardAsString(uint256 tokenId)
        public
        view
        returns (string memory boardStr)
    {
        console.log("getBoardAsString()");
        require(_exists(tokenId), "getBoardAsString: nonexistent token");
        boardStr = _playerBoards[tokenId].boardStr;
        console.log(boardStr);
    }

    // The following functions are overrides required by Solidity.
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
