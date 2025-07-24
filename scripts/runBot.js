require('dotenv').config();
const { ethers } = require("hardhat");
const axios = require("axios");

// CONFIG
const BEND_DAO_API = "https://api.benddao.xyz/api/v1/liquidations";
const BLUR_API = "https://api.thegraph.com/subgraphs/name/blur-exchange/blur";

// Strategy thresholds
const MIN_PROFIT_ETH = 0.2; // Your floor profit margin
const GAS_ESTIMATE_ETH = 0.015;

async function fetchLiquidations() {
  const res = await axios.get(BEND_DAO_API);
  return res.data?.data || [];
}

async function estimateProfit(nft) {
  // Get floor price from Blur or LooksRare
  // Placeholder: Assume 1.8 ETH floor
  const floorPrice = 1.8;
  const debt = parseFloat(nft.debt) || 1.4;

  return floorPrice - debt - GAS_ESTIMATE_ETH;
}

async function run() {
  const liquidations = await fetchLiquidations();
  for (let nft of liquidations) {
    const profit = await estimateProfit(nft);
    if (profit >= MIN_PROFIT_ETH) {
      console.log(`🟢 Target Found: ${nft.name} | Estimated Profit: ${profit} ETH`);
      // Call smart contract here (using ethers.js)
      // await contract.executeLiquidation(...);
    } else {
      console.log(`🔴 Skipped: ${nft.name} | Profit too low`);
    }
  }
}

run();