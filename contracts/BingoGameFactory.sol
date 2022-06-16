// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "hardhat/console.sol";

import "contracts/BingoGame.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract BingoGameFactory {
    using EnumerableSet for EnumerableSet.UintSet;

    uint256 public constant MIN_WEI_BUY_IN = 1;
    uint8 public constant MIN_NUM_PLAYERS = 5;
    uint256 public constant MAX_CARDS_PER_PLAYERS = 10;

    address public bingoGame;

    // We define an internal struct of properties to easily return an array of active GameProposals
    // to the front-end in `getActiveGameProposals`
    struct GameProposalProperties {
        uint256 gameUUID;
        uint256 weiBuyIn;
        uint256 totalCardCount;
        uint8 numPlayersRequired;
        uint8 numPlayersSignedUp;
    }

    struct GameProposal {
        GameProposalProperties properties;
        mapping(address => uint8) playersCardCount;
    }
    GameProposal private none;

    uint256 private gamesUUIDCounter = 1;

    // Mapping of gameUUID to GameProposal
    mapping(uint256 => GameProposal) private gameProposals;

    // List of all games waiting to be started
    EnumerableSet.UintSet private activeGameUUIDs;

    event GameProposed(
        uint256 gameUUID,
        uint256 weiBuyIn,
        uint8 numPlayersRequired
    );
    event GameCreated(
        uint256 gameUUID,
        address bingoGameContract,
        uint256 numPlayers,
        uint256 jackpot
    );

    constructor(address _bingoGame) {
        bingoGame = _bingoGame;
    }

    // External functions
    // ...
    function createGameProposal(
        uint256 weiBuyIn,
        uint8 numPlayersRequired,
        uint8 numCardsDesired
    ) external payable {
        require(weiBuyIn >= MIN_WEI_BUY_IN, "MIN_WEI_BUY_IN not met");
        require(
            numPlayersRequired >= MIN_NUM_PLAYERS,
            "MIN_NUM_PLAYERS not met"
        );
        require(
            msg.value >= weiBuyIn * numCardsDesired,
            "Value must be >= weiBuyIn * numCardsDesired"
        );

        GameProposal storage gameProposal = gameProposals[gamesUUIDCounter];

        require(
            numCardsDesired <= MAX_CARDS_PER_PLAYERS,
            "May not request more than MAX_CARDS_PER_PLAYERS"
        );

        // Initialize the GameProposal
        gameProposal.properties.gameUUID = gamesUUIDCounter++;
        gameProposal.properties.weiBuyIn = weiBuyIn;
        gameProposal.properties.numPlayersRequired = numPlayersRequired;
        gameProposal.properties.numPlayersSignedUp = 1; // creation only has 1 player
        gameProposal.playersCardCount[msg.sender] = numCardsDesired;
        gameProposal.properties.totalCardCount = numCardsDesired;

        // Add the newly created gameProposal to the activeGameUUIDs set
        activeGameUUIDs.add(gameProposal.properties.gameUUID);

        emit GameProposed(
            gameProposal.properties.gameUUID,
            gameProposal.properties.weiBuyIn,
            gameProposal.properties.numPlayersRequired
        );
    }

    function joinGameProposal(uint256 gameUUID, uint8 numCardsDesired)
        external
        payable
    {
        require(
            activeGameUUIDs.contains(gameUUID),
            "Must select an active gameProposal"
        );

        GameProposal storage gameProposal = gameProposals[gameUUID];

        require(
            gameProposal.playersCardCount[msg.sender] + numCardsDesired <=
                MAX_CARDS_PER_PLAYERS,
            "May not request more than MAX_CARDS_PER_PLAYERS"
        );
        require(
            msg.value >= gameProposal.properties.weiBuyIn * numCardsDesired,
            "Value must be >= weiBuyIn * numCardsDesired"
        );

        // Only increment numPlayersSignedUp if it's a new player
        gameProposal.properties.numPlayersSignedUp += gameProposal
            .playersCardCount[msg.sender] == 0
            ? 1
            : 0;
        gameProposal.playersCardCount[msg.sender] += numCardsDesired;
        gameProposal.properties.totalCardCount += numCardsDesired;

        if (
            gameProposal.properties.numPlayersSignedUp >=
            gameProposal.properties.numPlayersRequired
        ) {
            uint256 jackpot = gameProposal.properties.weiBuyIn *
                gameProposal.properties.totalCardCount;
            address deployedClone = Clones.cloneDeterministic(
                bingoGame,
                bytes32(gameUUID)
            );
            emit GameCreated(
                gameUUID,
                deployedClone,
                gameProposal.properties.numPlayersSignedUp,
                jackpot
            );

            activeGameUUIDs.remove(gameProposal.properties.gameUUID);

            (bool sent, ) = deployedClone.call{value: msg.value}("");
            require(sent, "Funding deployed clone failed");
        }
    }

    // External functions that are view
    function getActiveGameProposals()
        external
        view
        returns (GameProposalProperties[] memory gameProposalProperties)
    {
        uint256 len = activeGameUUIDs.length();
        gameProposalProperties = new GameProposalProperties[](len);

        for (uint256 i = 0; i < len; i++) {
            gameProposalProperties[i] = gameProposals[activeGameUUIDs.at(i)]
                .properties;
        }
    }

    // External functions that are pure
    // ...

    // Public functions
    // ...

    // Internal functions
    // ...

    // Private functions
    // ...
}
