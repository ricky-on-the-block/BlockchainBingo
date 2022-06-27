import Alpine from 'alpinejs';
import { ethers } from 'ethers';
// import contractJson from '../data/artifacts/contracts/BingoGameFactory.sol/BingoGameFactory.json';
// import contractAddresses from './data/__config.json';
import BingoDApp from './BingoDApp';

window.Alpine = Alpine;

Alpine.data('bingodapp', () => (BingoDApp));
// Alpine.store('bingodapp', {
//     provider: undefined,

//     async connect() {
//         console.log("connect");
//         console.log(this.provider);
//         this.provider = new ethers.providers.Web3Provider(window.ethereum);
//         console.log(this.provider);
//     },

//     isConnected() {
//         return this.provider != undefined;
//     }
// });

Alpine.store('pageState', {
    _isLanding: true,

    isLanding() {
        return this._isLanding;
    },

    isDashboard() {
        return !this._isLanding;
    },

    toLanding() {
        this._isLanding = true;
    },

    toDashboard() {
        this._isLanding = false;
    }
});

Alpine.data('buttonClicked', () => ({
    clicked: false,

    click() {
        this.clicked = !this.clicked;
    }
}));

Alpine.start();