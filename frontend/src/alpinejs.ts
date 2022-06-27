import Alpine from 'alpinejs';
import popularDestinations from './data/popularDestinations';
import BingoDApp from './BingoDApp';

window.Alpine = Alpine;

// INITIALIZE ALL CONTRACTS HERE

console.log(popularDestinations);
Alpine.store('dests', popularDestinations);
Alpine.data('bingodapp', () => (BingoDApp));

enum PageState {
    LandingPage,
    Dashboard
}
Alpine.store('pageState', {
    pageState: PageState.LandingPage,

    isLanding() {
        test();
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

function test() {
    console.log("TEST WEEE TEST");
    console.log(Alpine.store('pageState').isDashboard());
}

Alpine.data('buttonClicked', () => ({
    clicked: false,

    click() {
        this.clicked = !this.clicked;
    }
}));

Alpine.start();
