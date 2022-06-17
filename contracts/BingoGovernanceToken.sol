// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";

contract BingoGovernanceToken is ERC20Votes {
    uint256 public s_maxSupply = 1000000000000000000000000; //100,000,000 tokens

    constructor()
        ERC20("BingoGovernance", "BINGOGOV")
        ERC20Permit("BingoGovernance")
    {
        _mint(msg.sender, s_maxSupply);
    }

    //snapshot function, mint & _burn
    //Need to override the functions from the ERC20Votes.sol contract in order to keep the snapshot updated
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20Votes) {
        super._afterTokenTransfer(from, to, amount);
    }

    function _mint(address to, uint256 amount) internal override(ERC20Votes) {
        super._mint(to, amount);
    }

    function _burn(address account, uint256 amount)
        internal
        override(ERC20Votes)
    {
        super._burn(account, amount);
    }
}
