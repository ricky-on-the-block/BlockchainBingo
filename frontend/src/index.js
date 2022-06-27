const BingoGame = require('../artifacts/contracts/contracts/BingoGame.sol/BingoGame.json');
const BingoGameFactory = require('../artifacts/contracts/contracts/BingoGameFactory.sol/BingoGameFactory.json');
const BingoBoardNFT = require('../artifacts/contracts/contracts/BingoBoardNFT.sol/BingoBoardNFT.json');
const BingoSBT = require('../artifacts/contracts/contracts/BingoSBT.sol/BingoSBT.json');

const address = require('./__config.json');
const ethers = require('ethers');

// NOTE: Default provider has .connection.url set to "http://localhost:8545", so not technically needed
const provider = new ethers.providers.JsonRpcProvider("http://localhost:8545");
// console.log(provider);

// TODO: These signers do not have valid private keys. They are only objects
//       of type ethers.Signer. We need, instead, to make a signer using a
//       private key and the provider
let signer0 = provider.getSigner(0);
console.log(signer0);

// TODO: Read the the notes on ethersjs documentation on Signer about it being an
//       abstract class. Wallet is the type we will want to use here. Although,
//       Metamask will take care of this for us in our full DApp
const account0PrivKey = "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80";
let validSigner = new ethers.Wallet(account0PrivKey, provider);
console.log(validSigner);

const account1PrivKey = "0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d";
let validSigner1 = new ethers.Wallet(account1PrivKey, provider);
console.log(validSigner);

const account2PrivKey = "0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a";
let validSigner2 = new ethers.Wallet(account2PrivKey, provider);
console.log(validSigner);

const account3PrivKey = "0x7c852118294e51e653712a81e05800f419141751be58f605c371e15141b007a6";
let validSigner3 = new ethers.Wallet(account3PrivKey, provider);
console.log(validSigner);

const account4PrivKey = "0x47e179ec197488593b187f80a00eb0da91f1b9d0b13f8733639f19c30a34926a";
let validSigner4 = new ethers.Wallet(account4PrivKey, provider);
console.log(validSigner);

const account5PrivKey = "0x8b3a350cf5c34c9194ca85829a2df0ec3153be0318b5e2d3348e872092edffba";
let validSigner5 = new ethers.Wallet(account5PrivKey, provider);
console.log(validSigner);

const account6PrivKey = "96ad2a0177be18009ef602030b2bda3e24f2c306c2ce0ed7e0602e8f07c2e717";
let validSigner6 = new ethers.Wallet(account6PrivKey, provider);
console.log(validSigner);


// NOTE: See the difference between validSigner and signer0. One has a valid 'address'
//       member variable, and the other does not. This means that our private key
//       has been integrated, and the public key derived from that private key
//       We now use this for any txn that needs signing.
// DOUBLE NOTE: Any 'read only' call does not need a Wallet to sign for it, because
//              all we are doing under the hood is calling the JSON-RPC Node - in this
//              case Hardhat `hh node` - and asking them to return view function data.
//              You can see this by looking at the function definitions in the abi for
//              any of our contracts and searching for 'view'. You'll see them all

console.log(address.bingoGameContract);
console.log(address.bingoGameFactoryContract);
console.log(address.bingoBoardNFTContract);
console.log(address.bingoGameSBTContract);

const BingoGameContract = new ethers.Contract(address.bingoGameContract, BingoGame.abi, provider);
const BingoGameFactoryContract = new ethers.Contract(address.bingoGameFactoryContract, BingoGameFactory.abi, provider);
const BingoBoardNFTContract = new ethers.Contract(address.bingoBoardNFTContract, BingoBoardNFT.abi, provider);
const BingoSBTContract = new ethers.Contract(address.bingoGameSBTContract, BingoSBT.abi, provider);

// BingoGameFactoryContract.on("GameProposed", (gameUUID, weiBuyIn, numPlayersRequired) => {
//     console.log(gameUUID, bingoGameContract, jackpot, players);
// });

// BingoGameFactoryContract.on("GameCreated", (gameUUID, bingoGameContract, jackpot, players) => {
//     console.log(gameUUID, bingoGameContract, jackpot, players);
// });

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
    const value = {value: ethers.utils.parseUnits("0.01", "ether")};

    tx0 = await BingoGameFactoryContract.connect(validSigner3).joinGameProposal(3,1, value);
    tx0.wait();

    // tx1 = await BingoGameFactoryContract.connect(validSigner1).joinGameProposal(2,1, value);
    // tx1.wait();
    // tx2 = await BingoGameFactoryContract.connect(validSigner2).joinGameProposal(2,1, value);
    // tx2.wait();
    
    // tx3 = await BingoGameFactoryContract.connect(validSigner1).joinGameProposal(3,1, value);
    // tx3.wait();
    // tx4 = await BingoGameFactoryContract.connect(validSigner2).joinGameProposal(3,1, value);
    // tx4.wait();
    // tx5 = await BingoGameFactoryContract.connect(validSigner3).joinGameProposal(3,1, value);
    // tx5.wait();

    // tx6 = await BingoGameFactoryContract.connect(validSigner1).joinGameProposal(4,1, value);
    // tx6.wait();
    // tx7 = await BingoGameFactoryContract.connect(validSigner2).joinGameProposal(4,1, value);
    // tx7.wait();
    // tx8 = await BingoGameFactoryContract.connect(validSigner3).joinGameProposal(4,1, value);
    // tx8.wait();
    // tx9 = await BingoGameFactoryContract.connect(validSigner4).joinGameProposal(4,1, value);
    // tx9.wait();
    // TODO: Turn these game proposals into actual wallets with valid private keys
    // HOWEVER: We don't need to do this part, and have already tested this flow in our
    //          HH tests. Instead, we just want to expose all the functionality we will
    //          need for the front-end. If you look at the GUI, you can deduce that
    //          functionality
    // tx1 = await BingoGameFactoryContract.connect(signer1).joinGameProposal(1,2, value);
    // tx2 = await BingoGameFactoryContract.connect(signer2).joinGameProposal(1,2, value);
    // tx3 = await BingoGameFactoryContract.connect(signer3).joinGameProposal(1,2, value);
    // tx4 = await BingoGameFactoryContract.connect(signer4).joinGameProposal(1,2, value);
    // tx5 = await BingoGameFactoryContract.connect(signer5).joinGameProposal(1,2, value);  
    
    console.log(tx0);
}

async function drawNumbers() {
    let cloneAddress = ["0x0DbCb752EAab08F1E7Ae7b57Bb6DAAcE6B8a377B",
                        "0xC0099b5681b7262F4922082a85DE687A61cc420c",
                        "0x3429631cAa8E975e82ae5D0bc006a8E3C010ee20",
                        // "0x755539d974d7363601f16c44ae1ec584503781AB"                    
                    ]

    for(let i=0; i<cloneAddress.length; i++){

        let cloneContract = new ethers.Contract(cloneAddress[i], BingoGame.abi, provider);
        tx = await cloneContract.connect(validSigner1).drawNumber();   
        tx.wait();
        
    }
    

}

async function drawNumber() {
    let cloneContract = new ethers.Contract("0x0DbCb752EAab08F1E7Ae7b57Bb6DAAcE6B8a377B", BingoGame.abi, provider);
    tx = await cloneContract.connect(validSigner1).drawNumber();   
    tx.wait();
    }
    


async function getListOfTokenIDs() {
    // tx = await BingoBoardNFTContract.connect(validSigner2).getPlayerBoardsData();
    tx = await BingoBoardNFTContract.getListOfTokenIDs(validSigner1.address);
    console.log(tx.length);
 }



async function getActiveGameProposals() {
   tx = await BingoGameFactoryContract.getActiveGameProposals().toString();
   console.log(tx);
}


async function maxCards() {
    console.log("maxCards()");
    tx = await BingoGameFactoryContract.MAX_CARDS_PER_PLAYER();
    console.log(tx);
}


// createGameProposal();
joinGameProposal();
// getActiveGameProposals()
// getDrawnNumbers();
// maxCards();
// drawNumbers();

// getListOfTokenIDs()