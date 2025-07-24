const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("LiquidationBot", function () {
  it("should initiate a flash loan and liquidate NFT", async function () {
    const [deployer] = await ethers.getSigners();

    const Bot = await ethers.getContractFactory("LiquidationBot");
    const bot = await Bot.deploy("0x...AaveProvider"); // replace with actual address

    await bot.updateTargets("0x...NFTContract", "0x...Marketplace");

    const tx = await bot.requestFlashLoan(
      "0x...WETH", // token
      ethers.utils.parseEther("10"), // amount
      "0x...BorrowerAddress", // NFT borrower
      1234 // Token ID
    );

    await tx.wait();
    console.log("Flash loan requested");
  });
});
