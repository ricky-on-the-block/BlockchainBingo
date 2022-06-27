import { ethers } from 'ethers';
import contractJson from '../../data/artifacts/contracts/BingoGame.sol/BingoGame.json';
import contractAddresses from '../../data/__config.json';


// Contracts needed
// bingoBoardNFTContract
// bingoGameContract
// bingoGameFactoryContract
// 


export let gameStore = {
  name: 'gameStore',
  obj: {
    contract: undefined,
    address: undefined,

    async connect(wallet) {
      this.contract = new ethers.Contract(contractAddresses.bingoGameContract, contractJson.abi, wallet);
      console.log('this.contract:');
      console.log(this.contract);
    },

        // TODO: Add functions as they are needed for calling this contract

        //returns array of player TokenIDs 
        async getPlayerTokenIDs(){
            let listTokenIDs = await this.bingoBoardNFTContract.getListOfTokenIDs(this.address);
            console.log("List of TokenID: %s", listTokenIDs);

            return listTokenIDs
        },
        //returns array of gameUUIDs player has boards from
        async getPlayerGames() {
            let listTokenIDs = getListTokenIDs();
            let partOfGames = [];

            for(let x=0; x<listTokenIDs.length; x++){
                                    
                let tokenID = listTokenIDs[x].toNumber();
                console.log(tokenID);
                let playerboard = await this.bingoBoardNFTContract.getPlayerBoardData(tokenID);
                // console.log(playerboard);
                let gameUUID = (playerboard[0]).toNumber();

                if(!partOfGames.includes(gameUUID)){
                    partOfGames.push(gameUUID);
                    }

                let boardArray = []
                for(let y=1; y<playerboard.length; y++){
                    for(let z=0; z<playerboard[y].length; z++){
                        boardArray.push(playerboard[y][z]);
                        console.log("Game %s => %s ", gameUUID ,boardArray);
                        }
                
                }
            }
            console.log(partOfGames);
            return partOfGames;
        },
        //returns array of clone addresses
        async getCloneAddressess(){
            this.bingoGameCloneAddresses = [];

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
                
                this.bingoGameCloneAddresses.push(bingoGameCloneCreation);
            }
            // console.log("Overview of GameUUID paired to Address : %s", this.gameUUIDToAddress);
            console.log(this.bingoGameCloneAddresses);
            return this.bingoGameCloneAddresses
        },
        //returns array of objects {gameUUID with array playerboards}
        async getPlayerStatePerGame(){
            let games = this.getPlayerGames();
            let clones = this.getClonesAddressess();

            let playerGameState = [];

            for(let i=0; i<clones.length; i++){
                let gameUUID = clones[i][0];
                let cloneAddress = clones[i][1];
                let tokenIDs = this.getPlayerTokenIDs();

                let playerboardsPerGame = {
                    gameUUID: null,
                    playerBoards: [],
                };

                if(games.includes(gameUUID)){
                    let gameState = new playerboardsPerGame;
                    gameState.gameUUID = gameUUID;

                    for (let x=0; x<tokenIDs.length; x++){
                        let activeInGame = await this.bingoBoardNFTContract.isNFTInGame(tokenIDs[x], gameUUID);

                        if(activeInGame){
                            let playerboard = await this.bingoBoardNFTContract.getPlayerBoardData(tokenID);
                            let boardArray = []
                            for(let y=1; y<playerboard.length; y++){
                                for(let z=0; z<playerboard[y].length; z++){
                                    boardArray.push(playerboard[y][z]);
                                } 
                            }
                            gameState.playerBoards.push(boardArray);
                            console.log(boardArray);

                        }
                    }

                    playerGameState.push(gameState);
                }
            }
            console.log(playerGameState);
            return playerGameState
        }
}}
