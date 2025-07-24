require("dotenv").config();
const axios = require("axios");
const { ethers } = require("hardhat");

const blurAPI = "https://api.blur.io/collections"; // Example

async function getFloorPrice(collectionSlug) {
  const { data } = await axios.get(`${blurAPI}/${collectionSlug}`);
  return data.floorPrice;
}

async function runBot() {
  const floor = await getFloorPrice("azuki");
  const onChainFloor = await getOnChainPrice();

  if (floor < onChainFloor * 0.9) {
    console.log("Opportunity found!");

    const Bot = await ethers.getContractFactory("LiquidationBot");
    const bot = await Bot.attach(process.env.BOT_ADDRESS);

    const tx = await bot.requestFlashLoan(
      process.env.FLASH_ASSET,
      ethers.utils.parseEther("10"),
      process.env.BORROWER,
      process.env.TOKEN_ID
    );

    await tx.wait();
    console.log("Liquidation executed.");
  }
}

runBot().catch(console.error);
