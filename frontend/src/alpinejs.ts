import Alpine from 'alpinejs';
import popularDestinations from './data/popularDestinations';
import { ethers } from 'ethers';

window.Alpine = Alpine;
const metamaskProvider = new ethers.providers.Web3Provider(window.ethereum, "any");

console.log(popularDestinations);
Alpine.store('dests', popularDestinations);

enum PageState {
    LandingPage,
    Dashboard
}
Alpine.store('pageState', {
    pageState: PageState.LandingPage,

    isLanding() {
        console.log("isLanding() called");
        return this.pageState === PageState.LandingPage;
    },

    isDashboard() {
        console.log("isDashboard() called");
        return this.pageState === PageState.Dashboard;
    },

    toLanding() {
        console.log("toLanding() called");
        return this.pageState = PageState.LandingPage;
    },

    toDashboard() {
        console.log("toDashboard() called");
        return this.pageState = PageState.Dashboard;
    }
});

Alpine.data('test', () => ({
    open: false,

    toggle() {
        console.log("toggle");
    }
}));

Alpine.data('wallet', () => ({
    provider: null,
    signer: null,
    address: null,

    async connect() {
        console.log("connect");
        this.provider = metamaskProvider;
        console.log(this.provider);

        await this.provider.send("eth_requestAccounts", [])

        this.signer = this.provider.getSigner();
        console.log(this.signer);

        this.address = await this.signer.getAddress();
        console.log(this.address);
    },

    async disconnect() {
        await this.provider.close();
        this.provider = null;
    }
}));

Alpine.start();
