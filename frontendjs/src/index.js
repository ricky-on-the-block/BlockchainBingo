import Alpine from 'alpinejs';

// IMPORT GLOBAL STORES
import { walletStore } from './stores/walletStore';
import { pageStateStore } from './stores/pageStateStore';
import { gameFactoryStore } from './stores/gameFactoryStore';
import { gameStore } from './stores/gameStore';
import { boardNFTStore } from './stores/boardNFTStore';
import { sbtStore } from './stores/sbtStore';

// IMPORT COMPONENT DATA
import { gameProposalData } from './datums/gameProposalData';

// INITIALIZE GLOBAL STORES
Alpine.store(walletStore.name, walletStore.obj);
Alpine.store(pageStateStore.name, pageStateStore.obj);
Alpine.store(gameFactoryStore.name, gameFactoryStore.obj);
Alpine.store(gameStore.name, gameStore.obj);
Alpine.store(boardNFTStore.name, boardNFTStore.obj);
Alpine.store(sbtStore.name, sbtStore.obj);

// INITIALIZE GLOBAL DATA
Alpine.data(gameProposalData.name, gameProposalData.func);
// TODO: Create new stores for each repeating element in the front end
// 1. Running Games - Bingo Game Clone
// 1.a. drawnNumbers
// 1.b. Player's Bingo Cards

Alpine.data('buttonClicked', () => ({
  clicked: false,

  click() {
    this.clicked = !this.clicked;
  },
}));

Alpine.start();
