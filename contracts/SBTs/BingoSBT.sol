// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC4973.sol";
import "./IBingoSBT.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract BingoSBT is ERC4973, Ownable, IBingoSBT {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    constructor() ERC4973("BingoSBT", "BSBT") {}

    function mint(address issuee, string calldata uri) public onlyOwner {
        _mint(issuee, _tokenIdCounter.current(), uri);
        _tokenIdCounter.increment();
    }
}
