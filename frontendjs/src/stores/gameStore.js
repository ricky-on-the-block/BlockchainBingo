import { ethers } from 'ethers';
import contractJson from '../../data/artifacts/contracts/BingoGame.sol/BingoGame.json';
import contractAddresses from '../../data/__config.json';

export let gameStore = {
    name: 'gameStore',
    obj: {
        contract: undefined,
        address: undefined,

        async connect(wallet) {
            this.contract = new ethers.Contract(contractAddresses.bingoGameContract, contractJson.abi, wallet); 
            console.log("this.contract:");
            console.log(this.contract);        },

        // TODO: Add functions as they are needed for calling this contract
    }
};