import Alpine from 'alpinejs';

// IMPORT GLOBAL STORES
import { walletStore } from './stores/walletStore';
import { pageStateStore } from './stores/pageStateStore';
import { gameFactoryStore } from './stores/gameFactoryStore';

// IMPORT COMPONENT DATA
import { gameProposalData } from './datums/gameProposalData';

// INITIALIZE GLOBAL STORES
Alpine.store(walletStore.name, walletStore.obj);
Alpine.store(pageStateStore.name, pageStateStore.obj);
Alpine.store(gameFactoryStore.name, gameFactoryStore.obj);

// INITIALIZE GLOBAL DATA
Alpine.data(gameProposalData.name, gameProposalData.func);

Alpine.data('buttonClicked', () => ({
  clicked: false,

  click() {
    this.clicked = !this.clicked;
  },
}));

Alpine.start();
