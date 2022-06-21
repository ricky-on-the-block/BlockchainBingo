// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC4973.sol";
import "./IBingoSBT.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract BingoSBT is ERC4973, IBingoSBT {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    mapping(address => bool) private owners;
    mapping(address => bool) private hasSBT; 

    modifier onlyOwner() {
        require(owners[msg.sender]);
        _;
    }
    
    constructor() ERC4973("BingoSBT", "BSBT") {
        owners[msg.sender] = true;
    }

    function addOwner(address _owner) public onlyOwner {
        owners[_owner] = true;
    }

    function mint(address issuee, string calldata uri) public onlyOwner {
        require(!hasSBT[msg.sender]);
        _mint(issuee, _tokenIdCounter.current(), uri);
        _tokenIdCounter.increment();
    }

    function transferOwnership(address _newOwner) onlyOwner public {
        owners[_newOwner] = true;
        owners[msg.sender] = false;
    }



}
