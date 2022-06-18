// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./EIP4973.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BingoSBT is ERC4973, Ownable {
    uint256 public count = 0;

    constructor() ERC4973("BingoSBT", "BSBT") {}

    function burn(uint256 _tokenId) public override {
        require(ownerOf(_tokenId) == msg.sender, "You can't revoke this token");
        _burn(_tokenId);
    }

    function issue(address _issuee, string calldata _uri) external onlyOwner {
        _mint(_issuee, count, _uri);
        count += 1;
    }
}
