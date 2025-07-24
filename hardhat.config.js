require("@nomiclabs/hardhat-ethers");
require("dotenv").config();

module.exports = {
  solidity: "0.8.20",
  networks: {
    mainnet: {
      url: process.env.MAINNET_RPC,
      accounts: [process.env.PRIVATE_KEY],
    },
  },
};
