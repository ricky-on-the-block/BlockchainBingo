// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IBingoSBT {
    function mint(address issuee, string calldata uri) external;
}
