require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-etherscan");
require("dotenv").config({ path: ".env" });

const RINKEBY_ALCHEMY_API_KEY_URL = process.env.RINKEBY_ALCHEMY_API_KEY_URL;
const ROPSTEN_ALCHEMY_API_KEY_URL = process.env.ROPSTEN_ALCHEMY_API_KEY_URL;
const GOERLI_ALCHEMY_API_KEY_URL = process.env.ROPSTEN_ALCHEMY_API_KEY_URL;

const PRIVATE_KEY = process.env.PRIVATE_KEY;

module.exports = {
  solidity: "0.8.9",
  networks: {
    ropsten: {
      url: ROPSTEN_ALCHEMY_API_KEY_URL,
      accounts: [PRIVATE_KEY],
    },
    rinkeby: {
      url: RINKEBY_ALCHEMY_API_KEY_URL,
      accounts: [PRIVATE_KEY],
    },
    goerli: {
      url: RINKEBY_ALCHEMY_API_KEY_URL,
      accounts: [PRIVATE_KEY]
    },

  }
};