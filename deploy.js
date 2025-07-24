const { ethers } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying contract with the account:", deployer.address);

  const balance = await deployer.getBalance();
  console.log("Account balance:", ethers.utils.formatEther(balance), "ETH");

  const LiquidationBot = await ethers.getContractFactory("LiquidationBot");

  // Replace with real addresses if needed
  const bendDaoAddress = "0x0000000000000000000000000000000000000000"; // Placeholder
  const aavePoolAddress = "0x0000000000000000000000000000000000000000"; // Placeholder
  const blurMarketplaceAddress = "0x0000000000000000000000000000000000000000"; // Placeholder

  const contract = await LiquidationBot.deploy(
    bendDaoAddress,
    aavePoolAddress,
    blurMarketplaceAddress
  );

  console.log("Contract deployed at:", contract.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
