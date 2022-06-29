export let pageStateStore = {
  name: 'pageState',
  obj: {
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
    },
  },
};
