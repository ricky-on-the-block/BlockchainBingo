import Alpine from 'alpinejs';
import { ethers, BigNumber } from 'ethers';
import bingoBoardNFTJson from '../../data/artifacts/contracts/BingoBoardNFT.sol/BingoBoardNFT.json';
import bingoSBTJson from '../../data/artifacts/contracts/BingoSBT.sol/BingoSBT.json';
import bingoGameJson from '../../data/artifacts/contracts/BingoGame.sol/BingoGame.json';
import bingoGameFactoryJson from '../../data/artifacts/contracts/BingoGameFactory.sol/BingoGameFactory.json';
import contractAddresses from '../../data/__config.json';

let BingoBoardNFTContract, BingoSBTContract, BingoGameContract, BingoGameFactoryContract;

// Run checks for drawnNumbers on a loop, because we can't get events to work on clones
setInterval(async () => {
  for (let i = 0; i < Alpine.store(globalStore.name).gameObjArr.length; i++) {
    const drawnNumbers = await BingoGameContract.attach(Alpine.store(globalStore.name).gameObjArr[i].bingoCloneAddress).getDrawnNumbers();
    Alpine.store(globalStore.name).gameObjArr[i].drawnNumbers = drawnNumbers;
    console.log("trying to get drawnNumbers");
  }
}, 10000);

async function GameProposedListener(gameUUIDBN, weiBuyInBN, numPlayersRequired, minDrawTimeIntervalSec) {
  const gameUUID = gameUUIDBN.toNumber();
  if (!Alpine.store(globalStore.name).gameProposalMap.has(gameUUID)) {
    Alpine.store(globalStore.name).gameProposalMap.set(gameUUID, {
      gameUUID,
      gameUUIDBN,
      weiBuyIn: weiBuyInBN,
      numPlayersSignedUp: 1,
      numPlayersRequired,
      minDrawTimeIntervalSec,
    });
  }

  // Update game proposal array - needed by Alpine JS, because it can't use maps natively
  Alpine.store(globalStore.name).gameProposalObjsArr = [...Alpine.store(globalStore.name).gameProposalMap.values()];
}

async function PlayerJoinedProposalListener(gameUUIDBN, address) {
  const gameUUID = gameUUIDBN.toNumber();

  if (Alpine.store(globalStore.name).gameProposalMap.has(gameUUID)) {
    let gp = Alpine.store(globalStore.name).gameProposalMap.get(gameUUID);
    gp.numPlayersSignedUp++;

    Alpine.store(globalStore.name).gameProposalMap.set(gameUUID, gp);
  }
}

async function GameCreatedListener(gameUUIDBN, bingoCloneAddress, jackpot, players) {
  const gameUUID = gameUUIDBN.toNumber();

  Alpine.store(globalStore.name).gameProposalMap.delete(gameUUID);

  if (players.includes(Alpine.store('wallet').walletAddress)) {
    Alpine.store(globalStore.name).gameMap.set(gameUUID, {
      gameUUID,
      gameUUIDBN,
      bingoCloneAddress,
      jackpot,
      players,
    });
  }

  // Update game proposal array - needed by Alpine JS, because it can't use maps natively
  Alpine.store(globalStore.name).gameProposalObjsArr = [...Alpine.store(globalStore.name).gameProposalMap.values()];
  Alpine.store(globalStore.name).gameObjArr = [...Alpine.store(globalStore.name).gameMap.values()];

  Alpine.store(globalStore.name).setupBingoBoards();
}

async function BingoClaimedListener(gameUUID, winner) {
  console.log(`BingoClaimedListener: gameUUID ${gameUUID}, winner ${winner}`);
}

async function WinningsDistributedListener(gameUUID, winner, awardAmount) {
  console.log(`WinningsDistributedListener: gameUUID ${gameUUID}, winner ${winner}, awardAmount ${awardAmount}`);
}

async function SetupGlobalContracts(wallet) {
  // Setup Global Contracts
  BingoBoardNFTContract = new ethers.Contract(contractAddresses.bingoBoardNFTContract, bingoBoardNFTJson.abi, wallet);
  BingoSBTContract = new ethers.Contract(contractAddresses.bingoGameSBTContract, bingoSBTJson.abi, wallet);
  BingoGameContract = new ethers.Contract(contractAddresses.bingoGameContract, bingoGameJson.abi, wallet);
  BingoGameFactoryContract = new ethers.Contract(contractAddresses.bingoGameFactoryContract, bingoGameFactoryJson.abi, wallet);

  // Setup Listeners
  BingoGameFactoryContract.on('GameProposed', GameProposedListener);
  BingoGameFactoryContract.on('PlayerJoinedProposal', PlayerJoinedProposalListener);
  BingoGameFactoryContract.on('GameCreated', GameCreatedListener);
}

export let globalStore = {
  name: 'global',
  obj: {
    gameProposalMap: new Map(), // gameUUID -> obj
    gameProposalObjsArr: [],
    gameMap: new Map(), // gameUUID -> obj
    gameArr: [],
    gameObjArr: [],
    gameBingoBoardsMap: new Map(), // gameUUID -> PlayerBoardData
    tokenIdTracked: [],     // tokenId -> bool

    async connect(wallet) {
      await SetupGlobalContracts(wallet);
      await this.setupGameProposals();
      await this.setupBingoBoards();
    },

    // We must do this for unknown reasons because after each txn, the front-end reads 1 less event from GameProposed
    async setupGameProposals() {
      let gameProposals = await BingoGameFactoryContract.getActiveGameProposals();

      for (const gp of gameProposals) {
        Alpine.store(globalStore.name).gameProposalMap.set(gp.gameUUID.toNumber(), {
          gameUUID: gp.gameUUID,
          weiBuyIn: gp.weiBuyIn,
          numPlayersSignedUp: gp.numPlayersSignedUp,
          numPlayersRequired: gp.numPlayersRequired,
          minDrawTimeIntervalSec: gp.minDrawTimeIntervalSec,
        });
      }

      // Sort the array
      Alpine.store(globalStore.name).gameProposalMap = new Map([...Alpine.store(globalStore.name).gameProposalMap.entries()].sort((a, b) => a[0] - b[0]));

      // Set the array that alpine uses
      Alpine.store(globalStore.name).gameProposalObjsArr = [...Alpine.store(globalStore.name).gameProposalMap.values()];
    },

    async setupBingoBoards() {
      let bingoBoards = await BingoBoardNFTContract.getPlayerBoardsData();

      for (const board of bingoBoards) {
        const gameUUID = board['gameUUID'].toNumber();

        const obj = {
          // gameUUID: board.gameUUID,
          tokenId: board['tokenId'],
          bCol: board['bColumn'],
          iCol: board['iColumn'],
          nCol: board['nColumn'],
          gCol: board['gColumn'],
          oCol: board['oColumn'],
          board: [...board.bColumn, ...board.iColumn, ...board.nColumn, ...board.gColumn, ...board.oColumn],
        };

        if (!Alpine.store(globalStore.name).gameBingoBoardsMap.has(gameUUID)) {
          Alpine.store(globalStore.name).gameBingoBoardsMap.set(gameUUID, [obj]);
          this.tokenIdTracked[obj.tokenId.toString] = true;
        } else if (this.tokenIdTracked[obj.tokenId.toString] != true) {
          let arr = Alpine.store(globalStore.name).gameBingoBoardsMap.get(gameUUID);

          arr.push(obj);
          Alpine.store(globalStore.name).gameBingoBoardsMap.set(gameUUID, arr);
        }
      }
    },

    async joinGame(gameUUID, weiBuyIn) {
      let numCardsDesired = 1;
      await BingoGameFactoryContract.joinGameProposal(gameUUID, numCardsDesired, { value: weiBuyIn.mul(numCardsDesired) });
    },

    async claimBingo(cloneContract, tokenId) {
      let hasWon = await BingoGameContract.attach(cloneContract).claimBingo(tokenId);
    },
  },
};
