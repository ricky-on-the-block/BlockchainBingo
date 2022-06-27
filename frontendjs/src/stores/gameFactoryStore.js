import { ethers, BigNumber } from 'ethers';
import bingoGameFactoryJson from '../../data/artifacts/contracts/BingoGameFactory.sol/BingoGameFactory.json';
import contractAddresses from '../../data/__config.json';

export let gameFactoryStore = {
    name: 'gameFactory',
    obj: {
        contract: undefined,
        address: undefined,
        activeGameProposals: [],

        async connect(wallet) {
            this.contract = new ethers.Contract(contractAddresses.bingoGameFactoryContract, bingoGameFactoryJson.abi, wallet); 
            console.log(`this.contract: ${this.contract}`);

            await this.updateActiveGameProposals();
        },

        async updateActiveGameProposals() {
            // TODO: Sort this array based on gameUUID, so front end renders it reliably
            this.activeGameProposals = await this.contract.getActiveGameProposals();
            console.log("this.activeGameProposals");
            console.log(this.activeGameProposals);
        },

        async joinGame(gameUUID, weiBuyIn, numCardsDesired) {
            console.log("gameFactory: joinGame()");
            console.log(gameUUID);
            console.log(weiBuyIn);
            
            await this.contract.joinGameProposal(gameUUID, numCardsDesired, {value: weiBuyIn.mul(numCardsDesired)});
        },
    }
};