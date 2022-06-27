import Alpine from 'alpinejs';

export let gameProposalData = {
    name: 'gameProposal',
    func: (_gameUUID, _weiBuyIn, _drawTimeIntervalSec, _numPlayersSignedUp, _numPlayersRequired) => ({
        gameUUID: _gameUUID,
        weiBuyIn: _weiBuyIn,
        drawTimeIntervalSec: _drawTimeIntervalSec,
        numPlayersSignedUp: _numPlayersSignedUp,
        numPlayersRequired: _numPlayersRequired,
        
        async joinGame() {
            console.log("gameProposal: joinGame()");
            console.log(this.gameUUID);

            // TODO: Update HTML so that user can request the desired number of cards
            //       For now, hardcode to 1
            await Alpine.store('gameFactory').joinGame(this.gameUUID, this.weiBuyIn, 1);
        },
    })
};