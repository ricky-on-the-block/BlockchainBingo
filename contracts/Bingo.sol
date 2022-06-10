// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "hardhat/console.sol";

import "contracts/IBingo.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Bingo is IBingo, Ownable {
    function joinGame() external {
        console.log("joinGame");
    }

    function startGame() external onlyOwner {
        console.log("startGame");
    }

    function drawNumber() external onlyOwner {
        console.log("drawNumber");
    }

    function claimBingo() external {
        console.log("claimBingo");
    }
}
