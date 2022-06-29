// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "hardhat/console.sol";

import "contracts/IBingoBoardNFT.sol";
import "contracts/IBingoGame.sol";
import "contracts/IBingoSBT.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract BingoGameFactory {
    uint256 public constant MIN_WEI_BUY_IN = 0.001 ether;
    uint256 public constant MAX_CARDS_PER_PLAYER = 6;
    uint8 public constant MIN_NUM_PLAYERS = 2;
    uint8 public constant MAX_DRAW_INTERVAL_SEC = 60;

    IBingoGame public bingoGame;
    IBingoBoardNFT public bingoBoardNFT;
    IBingoSBT public bingoSBT;

    // We define an internal struct of properties to easily return an array of active GameProposals
    // to the front-end in `getActiveGameProposals`
    struct GameProposalProperties {
        uint256 gameUUID;
        uint256 weiBuyIn;
        uint256 totalCardCount;
        uint8 minDrawTimeIntervalSec;
        uint8 numPlayersRequired;
        uint8 numPlayersSignedUp;
        address[] playersSignedUp;
    }

    struct GameProposal {
        GameProposalProperties properties;
        mapping(address => uint8) playersCardCount;
    }

    using Counters for Counters.Counter;
    Counters.Counter private gamesUUIDCounter;

    // Mapping of gameUUID to GameProposal
    mapping(uint256 => GameProposal) private gameProposals;

    // Add a list of all clones to easily read from the front end, because
    // using events in AlpineJS is a pain
    address[] public createdGames;
    mapping(uint256 => address) public gameClonesByUUID;

    // List of all games waiting to be started
    using EnumerableSet for EnumerableSet.UintSet;
    EnumerableSet.UintSet private proposedGameUUIDs;

    // -------------------------------------------------------------
    event GameProposed(
        uint256 gameUUID,
        uint256 weiBuyIn,
        uint8 numPlayersRequired,
        uint8 minDrawTimeIntervalSec
    );
    event PlayerJoinedProposal(
        uint256 gameUUID,
        address player
    );
    event GameCreated(
        uint256 gameUUID,
        address bingoGameContract,
        uint256 jackpot,
        address[] players
    );

    // -------------------------------------------------------------
    constructor(
        address _bingoGame,
        address _bingoBoardNFT,
        address _bingoSBT
    ) {
        bingoGame = IBingoGame(_bingoGame);
        bingoBoardNFT = IBingoBoardNFT(_bingoBoardNFT);
        bingoSBT = IBingoSBT(_bingoSBT);
    }

    // -------------------------------------------------------------
    function createGameProposal(
        uint256 weiBuyIn,
        uint8 minDrawTimeIntervalSec,
        uint8 numPlayersRequired,
        uint8 numCardsDesired
    ) external payable {
        console.log("createGameProposal()");
        require(weiBuyIn >= MIN_WEI_BUY_IN, "MIN_WEI_BUY_IN not met");
        require(
            minDrawTimeIntervalSec <= MAX_DRAW_INTERVAL_SEC,
            "minDrawTimeIntervalSec > MAX_DRAW_INTERVAL_SEC"
        );
        require(
            numPlayersRequired >= MIN_NUM_PLAYERS,
            "MIN_NUM_PLAYERS not met"
        );
        require(
            msg.value >= weiBuyIn * numCardsDesired,
            "Value must be >= weiBuyIn * numCardsDesired"
        );

        GameProposal storage gp = gameProposals[gamesUUIDCounter.current()];

        require(
            numCardsDesired <= MAX_CARDS_PER_PLAYER,
            "May not request more than MAX_CARDS_PER_PLAYER"
        );

        // Initialize the GameProposal
        gp.properties.gameUUID = gamesUUIDCounter.current();
        gp.properties.weiBuyIn = weiBuyIn;
        gp.properties.minDrawTimeIntervalSec = minDrawTimeIntervalSec;
        gp.properties.numPlayersSignedUp = 1; // creation only has 1 player
        gp.properties.numPlayersRequired = numPlayersRequired;
        gp.properties.playersSignedUp.push(msg.sender);
        gp.playersCardCount[msg.sender] = numCardsDesired;
        gp.properties.totalCardCount = numCardsDesired;

        for (uint256 i = 0; i < numCardsDesired; i++) {
            bingoBoardNFT.safeMint(msg.sender, gp.properties.gameUUID);
        }

        // Add the newly created gameProposal to the proposedGameUUIDs set
        proposedGameUUIDs.add(gp.properties.gameUUID);

        emit GameProposed(
            gp.properties.gameUUID,
            gp.properties.weiBuyIn,
            gp.properties.numPlayersRequired,
            gp.properties.minDrawTimeIntervalSec
        );

        gamesUUIDCounter.increment();
    }

    // -------------------------------------------------------------
    function joinGameProposal(uint256 gameUUID, uint8 numCardsDesired)
        external
        payable
    {
        console.log("joinGameProposal()");
        require(
            proposedGameUUIDs.contains(gameUUID),
            "Must select an active gameProposal"
        );

        GameProposal storage gp = gameProposals[gameUUID];

        require(
            gp.playersCardCount[msg.sender] + numCardsDesired <=
                MAX_CARDS_PER_PLAYER,
            "May not request more than MAX_CARDS_PER_PLAYER"
        );
        require(
            msg.value >= gp.properties.weiBuyIn * numCardsDesired,
            "Value must be >= weiBuyIn * numCardsDesired"
        );

        // Only increment numPlayersSignedUp if it's a new player
        if (gp.playersCardCount[msg.sender] == 0) {
            gp.properties.playersSignedUp.push(msg.sender);
            emit PlayerJoinedProposal(gameUUID, msg.sender);
        }
        gp.playersCardCount[msg.sender] += numCardsDesired;
        gp.properties.totalCardCount += numCardsDesired;

        for (uint256 i = 0; i < numCardsDesired; i++) {
            bingoBoardNFT.safeMint(msg.sender, gameUUID);
        }

        if (
            gp.properties.playersSignedUp.length >=
            gp.properties.numPlayersRequired
        ) {
            uint256 jackpot = gp.properties.weiBuyIn *
                gp.properties.totalCardCount;

            address deployedClone = Clones.cloneDeterministic(
                address(bingoGame),
                bytes32(gameUUID)
            );
            console.log(
                "BingoGame DEPLOYED CLONE @ %s with GameUUID: %s",
                deployedClone,
                gameUUID
            );
            IBingoGame(deployedClone).init{value: jackpot}(
                address(bingoBoardNFT),
                address(bingoSBT),
                gp.properties.gameUUID,
                gp.properties.minDrawTimeIntervalSec
            );
            createdGames.push(deployedClone);
            gameClonesByUUID[gp.properties.gameUUID] = deployedClone;

            bingoSBT.addOwner(deployedClone);

            emit GameCreated(
                gameUUID,
                deployedClone,
                jackpot,
                gp.properties.playersSignedUp
            );

            proposedGameUUIDs.remove(gp.properties.gameUUID);
            delete gameProposals[gameUUID];
        }
    }

    // -------------------------------------------------------------
    function getActiveGameProposals()
        external
        view
        returns (GameProposalProperties[] memory gameProposalProperties)
    {
        uint256 len = proposedGameUUIDs.length();
        gameProposalProperties = new GameProposalProperties[](len);

        for (uint256 i = 0; i < len; i++) {
            gameProposalProperties[i] = gameProposals[proposedGameUUIDs.at(i)]
                .properties;
        }
    }
    
    // -------------------------------------------------------------
    function getCreatedGames()
        external
        view
        returns (address[] memory _createdGames)
    {
        _createdGames = new address[](createdGames.length);
        _createdGames = createdGames;
    }
}
