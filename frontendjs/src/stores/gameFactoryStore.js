import { ethers, BigNumber } from 'ethers';
import bingoGameFactoryJson from '../../data/artifacts/contracts/BingoGameFactory.sol/BingoGameFactory.json';
import contractAddresses from '../../data/__config.json';

export let gameFactoryStore = {
  name: 'gameFactory',
  obj: {
    contract: undefined,
    address: undefined,
    activeGameProposals: [],
    gameCloneAddresses: [],

    async connect(wallet) {
      this.contract = new ethers.Contract(contractAddresses.bingoGameFactoryContract, bingoGameFactoryJson.abi, wallet);
      console.log('this.contract:');
      console.log(this.contract);

      // Read initial state of games on chain on connect
      await this.updateActiveGameProposals();
      await this.getGameCloneAddresses();
    },

    async updateActiveGameProposals() {
      // TODO: Sort this array based on gameUUID, so front end renders it reliably
      this.activeGameProposals = await this.contract.getActiveGameProposals();
      console.log('this.activeGameProposals');
      console.log(this.activeGameProposals);
    },

    async joinGame(gameUUID, weiBuyIn, numCardsDesired) {
      console.log('gameFactory: joinGame()');
      console.log(gameUUID);
      console.log(weiBuyIn);

      try {
        await this.contract.joinGameProposal(gameUUID, numCardsDesired, { value: weiBuyIn.mul(numCardsDesired) });
      } catch (err) {
        // Ignore txn error because Metamask logs it by default
      }
    },

    // TODO: Decide between this approach and reading all player-owned NFTs and sorting by game
    async getGameCloneAddresses() {
      console.log('gameFactory: getRunningGameAddresses()');
      this.gameCloneAddresses = await this.contract.getCreatedGames();
      console.log(this.gameCloneAddresses);
    },
  },
};
