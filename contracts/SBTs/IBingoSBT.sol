// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IBingoSBT {
    function issue(address _issuee, string calldata _uri) external;
}
