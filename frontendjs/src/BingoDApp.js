import { ethers } from 'ethers';
import contractJson from '../data/artifacts/contracts/BingoGameFactory.sol/BingoGameFactory.json';
import contractAddresses from '../data/__config.json';

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
    bingoGameFactory: null,
    activeGameProposals: [],

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

        this.bingoGameFactory = new ethers.Contract(contractAddresses.bingoGameFactoryContract, contractJson.abi, this.provider);   
        console.log(this.bingoGameFactory);
        // console.log(this.bingoGameFactory.filters);

        this.activeGameProposals = await this.bingoGameFactory.getActiveGameProposals();
        console.log(this.activeGameProposals);

        // this.bingoGameFactory.on('GameProposed', (gameUUID, weiBuyIn, numPlayersRequired) => {
        //     console.log(`gameUUID: ${gameUUID}, weiBuyIn: ${weiBuyIn}, numPlayersRequired: ${numPlayersRequired}`)
        // });
        // console.log(events);
    },

    async disconnect() {
        await this.provider.close();
        this.provider = null;
        this.isConnected = false;
    }
};

export default BingoDApp;
