// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "hardhat/console.sol";

import "contracts/SimpleRNG.sol";
import "contracts/IERC721Mintable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract BingoBoardNFT is ERC721, ERC721Enumerable, Ownable, SimpleRNG, IERC721Mintable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

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

    // Mapping from token ID to PlayerBoard
    mapping(uint256 => PlayerBoard) internal _playerBoards;

    // Per the Standard US Bingo Rules
    uint8 constant B_OFFSET = 0 * 15;
    uint8 constant I_OFFSET = 1 * 15;
    uint8 constant N_OFFSET = 2 * 15;
    uint8 constant G_OFFSET = 3 * 15;
    uint8 constant O_OFFSET = 4 * 15;

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
                ? append(" ", Strings.toString(uint256(boardColumn[i])))
                : Strings.toString(uint256(boardColumn[i]));

            boardStr = append(boardStr, elemStr, "  ");
        }
        return append(boardStr, "\n");
    }

    // -------------------------------------------------------------
    function generateBoardStr(PlayerBoard storage self)
        private
        view
        returns (string memory boardStr)
    {
        console.log("generateBoardStr()");

        boardStr = concatenateBoardStr(boardStr, self.bColumn);
        boardStr = concatenateBoardStr(boardStr, self.iColumn);
        boardStr = concatenateBoardStr(boardStr, self.nColumn);
        boardStr = concatenateBoardStr(boardStr, self.gColumn);
        boardStr = concatenateBoardStr(boardStr, self.oColumn);

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

        // Now generate the game board string, and save it
        self.boardStr = generateBoardStr(self);
    }

    constructor() ERC721("BingoBoardNFT", "BINGOBOARD") {}

    function safeMint(address to) public onlyOwner returns (uint256) {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);

        // Now generate a board, and tie it to the tokenId
        generateBoard(_playerBoards[tokenId]);

        return tokenId;
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
