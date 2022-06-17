// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IBingoBoardNFTMintable {
    function safeMint(address to, uint256 gameUUID) external returns (uint256);
}
