import Alpine from 'alpinejs';
import popularDestinations from './data/popularDestinations';

window.Alpine = Alpine;

console.log(popularDestinations);

Alpine.store('dests', popularDestinations);

Alpine.start();
