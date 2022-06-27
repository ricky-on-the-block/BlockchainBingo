import Alpine from 'alpinejs';
import { ethers } from 'ethers';
import { boardNFTStore } from './boardNFTStore';
import { gameFactoryStore } from './gameFactoryStore';
import { gameStore } from './gameStore';
import { sbtStore } from './sbtStore';

export let walletStore = {
    name: 'wallet',
    obj: {
        provider: undefined,
        wallet: undefined,
        walletAddress: undefined,
        isConnected: false,
    
        async connect() {
            try {
                this.provider = new ethers.providers.Web3Provider(window.ethereum, "any");
                await this.provider.send("eth_requestAccounts", []);
        
                this.wallet = this.provider.getSigner();
                this.walletAddress = await this.wallet.getAddress();
                
                // Now, setup global/constant contracts with this wallet
                Alpine.store(gameFactoryStore.name).connect(this.wallet);
                Alpine.store(gameStore.name).connect(this.wallet);
                Alpine.store(boardNFTStore.name).connect(this.wallet);
                Alpine.store(sbtStore.name).connect(this.wallet);

                this.isConnected = true;
                console.log("Metamask Connected!");
            }
            catch(error) {
                console.log(error);
            }
        },

        toggleConnection() {
            if(this.isConnected){
                this.wallet = undefined;
                this.walletAddress = undefined;
                this.isConnected = false;
            }
            else {
                this.connect();
            }
        }
    }
};
