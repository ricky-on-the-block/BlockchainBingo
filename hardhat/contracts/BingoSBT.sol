// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "hardhat/console.sol";

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
        // require(!hasSBT[issuee], "already have a SBT");
        _mint(issuee, _tokenIdCounter.current(), uri);
        _tokenIdCounter.increment();
        hasSBT[issuee] = true;
        console.log("SBT Minted to: %s with tokenID: %s", issuee, _tokenIdCounter.current());
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        owners[_newOwner] = true;
        owners[msg.sender] = false;
    }

    function isOwnerOfSBT(address _ownerToken) public view returns(bool isOwner){
        require(_ownerToken != address(0), "ownerOf: token doesn't exist");
        return hasSBT[_ownerToken];
    } 
}
