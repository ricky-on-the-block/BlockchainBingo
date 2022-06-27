import { ethers } from 'ethers';
import bingoGameFactory from '../artifacts/contracts/contracts/BingoGameFactory.sol/BingoGameFactory.json';
import bingoGame from '../artifacts/contracts/contracts/BingoGame.sol/BingoGame.json';
import bingoBoardNFT from '../artifacts/contracts/contracts/BingoBoardNFT.sol/BingoBoardNFT.json';
import contractAddresses from './__config.json';

// TODO: Add all the contracts and logic in this single data object. Any function that
//       makes a call to the chain to read the data will need to be `async`
//       Also, you need commas in between every function definition and variable
// NOTE: Notice that in alpinejs.ts, we are importing this and using it with:
//       `Alpine.data('bingodapp', () => (BingoDApp)), and x-data="bingodapp" is part of the
//       highest level body tag in the HTML. This means the whole document will have this data
//       object.
let BingoDApp = {
    provider: null,
    wallet: null,
    address: null,
    isConnected: false,
    bingoGameFactoryContract: null,
    bingoBoardNFTContract: null,
    activeGameProposals: [],
    bingoGameCloneAddresses: [],
    gameUUIDToAddress: {},

    async connect() {
        console.log("connect");
        this.provider = new ethers.providers.Web3Provider(window.ethereum, "any");
        console.log(this.provider);

        await this.provider.send("eth_requestAccounts", [])

        this.wallet = this.provider.getSigner();
        console.log(this.wallet);

        this.address = await this.wallet.getAddress();
        console.log(this.address);

        this.isConnected = true;

        this.bingoGameFactoryContract = new ethers.Contract(contractAddresses.bingoGameFactoryContract, bingoGameFactory.abi, this.provider);   
        console.log(this.bingoGameFactoryContract);

        this.activeGameProposals = await this.bingoGameFactoryContract.getActiveGameProposals();
        console.log(this.activeGameProposals);

        this.bingoBoardNFTContract = new ethers.Contract(contractAddresses.bingoBoardNFTContract, bingoBoardNFT.abi, this.provider);   
        console.log(this.bingoBoardNFTContract);

        // TODO: Get all Games the player is a part of
        // console.log(this.bingoGameFactoryContract.filters.GameCreated(null, null, null, null));
        this.bingoGameFactoryContract.on('GameCreated', (gameUUID, bingoGameContract, jackpot, players) => {
            console.log(`${gameUUID} ${bingoGameContract} ${jackpot} ${players}`);
        })

        let bingoBoardBalance = await this.bingoBoardNFTContract.balanceOf(this.address);
        console.log("Total number of bingo cards owned %s",bingoBoardBalance.toNumber());

        let listTokenIDs = await this.bingoBoardNFTContract.getListOfTokenIDs(this.address);
        console.log("List of TokenID: %s", listTokenIDs);

        // Add functions to display data 

        if(bingoBoardBalance.toNumber()!=0){
            this.filter = {
                fromBlock: 0,
                toBlock: "latest",
                address: contractAddresses.bingoGameFactoryContract,
                topics: [
                    "0x5d1773d537337c41dba8fc74656e5d12f8403fc01414699061532d4dc63a554d",
                    // "0x1bcd28d20b9e19e1f7347f46c4423e50472e81cbf9abe56269ca6b37a2faee0a" 
                ]
            };

            this.logs = await this.provider.getLogs(this.filter)
            console.log(this.logs);        

            let iFactory = new ethers.utils.Interface(bingoGameFactory.abi);
            console.log(iFactory);

            this.gameCreated = iFactory.getEvent("GameCreated(uint256,address,uint256,address[])");
            console.log(this.gameCreated)

            for(let i=0; i<this.logs.length; i++){
                let bingoGameCloneCreation = await iFactory.decodeEventLog(this.gameCreated, this.logs[i].data);
                // console.log(bingoGameCloneCreation);
                
                let bingoGameCloneAddress = bingoGameCloneCreation[1];
                // console.log(bingoGameCloneAddress);

                let bingoGameCloneGameUUID = bingoGameCloneCreation[0];
                // console.log(bingoGameCloneGameUUID);

                console.log("Game %s => address: %s", bingoGameCloneGameUUID,bingoGameCloneAddress);
               
                
                // this.gameUUIDToAddress.bingoGameCloneGameUUID = bingoGameCloneAddress;        
                
                this.bingoGameCloneAddresses.push(bingoGameCloneCreation);
            }
            // console.log("Overview of GameUUID paired to Address : %s", this.gameUUIDToAddress);
            console.log(this.bingoGameCloneAddresses);

            console.log("Number of clone addresses/games : %s", this.bingoGameCloneAddresses.length);
            

            // Get player info
            
            // New Logic 

            // let partOfGames = [];
            // for(let x=0; x<listTokenIDs.length; x++){
                
            //     let tokenID = listTokenIDs[x].toNumber();
            //     console.log(tokenID);
            //     let playerboard = await this.bingoBoardNFTContract.getPlayerBoardData(tokenID);
            //     // console.log(playerboard);
            //     let gameUUID = (playerboard[0]).toNumber();

            //     if(!partOfGames.includes(gameUUID)){
            //         partOfGames.push(gameUUID);
            //     }

            //     let boardArray = []
            //             for(let y=1; y<playerboard.length; y++){
            //                 for(let z=0; z<playerboard[y].length; z++){
            //                     boardArray.push(playerboard[y][z]);
            //                 } 
            //             }
            //     console.log("Game %s => %s ", gameUUID ,boardArray);

            // }

            // console.log(partOfGames);




            // OLD LOGIC!! 

            for(let i=0; i<this.bingoGameCloneAddresses.length; i++) {

                let gameUUID = (this.bingoGameCloneAddresses[i][0]).toNumber();
                // console.log(gameUUID);
                console.log("Game %s => START", gameUUID);

                let cloneAddress = this.bingoGameCloneAddresses[i][1];
                console.log("Game %s => address: %s", gameUUID, cloneAddress);

                this.bingoGameClone = new ethers.Contract(cloneAddress, bingoGame.abi, this.provider);   
                // console.log(this.bingoGameClone);

                let drawnNumbers = await this.bingoGameClone.getDrawnNumbers();
                console.log("Game %s => numbers: %s",gameUUID, drawnNumbers);

                // console.log(this.address);

                let boardsData = await this.bingoBoardNFTContract.getListOfTokenIDs(this.address);
                // console.log(boardsData);
                let count = 0;
                for(let x=0; x<boardsData.length; x++){
                    // let gameUUID = boardsData[x][0];
                    let tokenID = boardsData[x].toNumber();
                    
                    let activeInGame = await this.bingoBoardNFTContract.isNFTInGame(tokenID, gameUUID);
                    // console.log(activeInGame);

                    if(activeInGame){
                        console.log("Game %s => owner of tokenID %s", gameUUID, tokenID);
                        let playerboard = await this.bingoBoardNFTContract.getPlayerBoardData(tokenID);
                        // console.log(playerboard);
                        let boardArray = []
                        for(let y=1; y<playerboard.length; y++){
                            for(let z=0; z<playerboard[y].length; z++){
                                boardArray.push(playerboard[y][z]);
                            } 
                        }
                        console.log(boardArray);
                        count++;
                    }
                }
                console.log("Game %s => number of boards owned in this game %s", gameUUID, count);
                console.log("Game %s => END", gameUUID);
            }
        }
        else{
            console.log("Please Purchase a bingo board by joining a game")
        }
        

        
    },

    async disconnect() {
        await this.provider.close();
        this.provider = null;
        this.isConnected = false;
    }
};

export default BingoDApp;
