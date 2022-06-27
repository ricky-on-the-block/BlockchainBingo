export let pageStateStore = {
    name: 'pageState',
    obj: {
        _isLanding: true,
    
        isLanding() {
            console.log("isLanding()");
            return this._isLanding;
        },
    
        isDashboard() {
            console.log("isDashboard()");
            return !this._isLanding;
        },
    
        toLanding() {
            console.log("toLanding");
            this._isLanding = true;
        },
    
        toDashboard() {
            console.log("toDashboard()");
            this._isLanding = false;
        }
    }};