// scripts/runBot.js

require("dotenv").config(); const { ethers } = require("hardhat"); const axios = require("axios");

const BENDDAO_API = "https://api.benddao.xyz/api/v1/liquidations"; // Example endpoint const TARGET_PROFIT_ETH = ethers.utils.parseEther("0.2"); // Minimum profit threshold

async function fetchLiquidationTargets() { try { const response = await axios.get(BENDDAO_API); const liquidations = response.data?.data || []; return liquidations.filter(target => parseFloat(target.profit) >= parseFloat(ethers.utils.formatEther(TARGET_PROFIT_ETH))); } catch (error) { console.error("Error fetching liquidation targets:", error); return []; } }

async function runBot() { const [deployer] = await ethers.getSigners(); const LiquidationBot = await ethers.getContractFactory("LiquidationBot"); const bot = await LiquidationBot.attach(process.env.CONTRACT_ADDRESS);

const targets = await fetchLiquidationTargets();

if (targets.length === 0) { console.log("No profitable liquidation targets found at this moment."); return; }

for (const target of targets) { try { console.log(Attempting liquidation for target: ${target.nftId}); const tx = await bot.liquidate(target.nftId, target.debtAmount, { gasLimit: 8000000, }); await tx.wait(); console.log(Liquidation executed for ${target.nftId}); } catch (err) { console.error(Error executing liquidation for ${target.nftId}:, err); } } }

runBot();

  
