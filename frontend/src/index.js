const BingoGame = require('../artifacts/contracts/contracts/BingoGame.sol/BingoGame.json');
const BingoGameFactory = require('../artifacts/contracts/contracts/BingoGameFactory.sol/BingoGameFactory.json');
const BingoBoardNFT = require('../artifacts/contracts/contracts/BingoBoardNFT.sol/BingoBoardNFT.json');
const BingoSBT = require('../artifacts/contracts/contracts/BingoSBT.sol/BingoSBT.json');

const address = require('./__config.json');
const ethers = require('ethers');

// const url = "http://localhost:8545";

const provider = new ethers.providers.JsonRpcProvider();

// console.log(provider);

let signer0 = provider.getSigner(0);
let signer1 = provider.getSigner(1);
let signer2 = provider.getSigner(2);
let signer3 = provider.getSigner(3);
let signer4 = provider.getSigner(4);
let signer5 = provider.getSigner(5);


console.log(address.bingoGameContract);
console.log(address.bingoGameFactoryContract);
console.log(address.bingoBoardNFTContract);
console.log(address.bingoGameSBTContract);

const BingoGameContract = new ethers.Contract(address.bingoGameContract, BingoGame.abi, signer0);
const BingoGameFactoryContract = new ethers.Contract(address.bingoGameFactoryContract, BingoGameFactory.abi, signer0);
const BingoBoardNFTContract = new ethers.Contract(address.bingoBoardNFTContract, BingoBoardNFT.abi, signer0);
const BingoSBTContract = new ethers.Contract(address.bingoGameSBTContract, BingoSBT.abi, signer0);

// BingoGameFactoryContract.on("GameProposed", (gameUUID, weiBuyIn, numPlayersRequired) => {
//     console.log(gameUUID, bingoGameContract, jackpot, players);
// });

BingoGameFactoryContract.on("GameCreated", (gameUUID, bingoGameContract, jackpot, players) => {
    console.log(gameUUID, bingoGameContract, jackpot, players);
});


const checkGameProposed = async () => {
    BingoGameFactoryContract.on("GameProposed", (gameUUID, weiBuyIn, numPlayersRequired) => {
        console.log({
            gameUUID,
            weiBuyIn,
            numPlayersRequired,
        });
    })};

// console.log( async () => { await BingoGameContract.getDrawnNumbers()});

async function getDrawnNumbers() {
    tx = (await BingoGameContract.getDrawnNumbers());
    // tx = (await BingoGameContract.drawNumber());
    console.log(tx);
}

async function createGameProposal() {
    // BingoGameFactoryContract.on("GameProposed", (gameUUID, weiBuyIn, numPlayersRequired) => {
    //     console.log(gameUUID, bingoGameContract, jackpot, players);
    // });

    let amount = ethers.utils.parseUnits("1000000", "gwei");


    console.log(amount.toString());
    tx0 = await BingoGameFactoryContract.connect(signer0).createGameProposal(1000000000000000,5,5,1, {value: ethers.utils.parseUnits("1000000", "gwei")});
    checkGameProposed();
    console.log(tx0);
}

async function joinGameProposal() {
    console.log(BingoGameFactoryContract.functions);
    const value = {value: ethers.utils.parseUnits("1000000", "gwei")};
    tx0 = await BingoGameFactoryContract.connect(signer0).joinGameProposal(1,2, value);
    tx1 = await BingoGameFactoryContract.connect(signer1).joinGameProposal(1,2, value);
    tx2 = await BingoGameFactoryContract.connect(signer2).joinGameProposal(1,2, value);
    tx3 = await BingoGameFactoryContract.connect(signer3).joinGameProposal(1,2, value);
    tx4 = await BingoGameFactoryContract.connect(signer4).joinGameProposal(1,2, value);
    tx5 = await BingoGameFactoryContract.connect(signer5).joinGameProposal(1,2, value);  
    
    console.log(tx0);
}

async function getActiveGameProposals() {
   tx = await BingoGameFactoryContract.getActiveGameProposals().toString();
   console.log(tx);
}


async function maxCards() {
    // console.log(BingoGameFactoryContract.functions);
    // const options = {value: ethers.utils.parseEther("1")}
    tx = await BingoGameFactoryContract.MAX_CARDS_PER_PLAYERS;
    // tx.wait();
    
    console.log("maxCards()");
    console.log(tx);
    
}


// createGameProposal();
// joinGameProposal();
// getActiveGameProposals()
// getDrawnNumbers();
maxCards();