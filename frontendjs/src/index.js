import Alpine from 'alpinejs';

// IMPORT GLOBAL STORES
import { walletStore } from './stores/walletStore';
import { pageStateStore } from './stores/pageStateStore';
import { globalStore } from './stores/globalStore';

// INITIALIZE GLOBAL STORES
Alpine.store(walletStore.name, walletStore.obj);
Alpine.store(pageStateStore.name, pageStateStore.obj);
Alpine.store(globalStore.name, globalStore.obj);

Alpine.data('buttonClicked', () => ({
  clicked: false,

  click() {
    this.clicked = !this.clicked;
  },
}));

Alpine.start();
