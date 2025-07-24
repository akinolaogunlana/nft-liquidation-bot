// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@aave/core-v3/contracts/flashloan/base/FlashLoanSimpleReceiverBase.sol";
import "@aave/core-v3/contracts/interfaces/IPoolAddressesProvider.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract LiquidationBot is FlashLoanSimpleReceiverBase, Ownable {
    address public liquidationTarget;
    address public nftMarketplace;

    constructor(address _provider) FlashLoanSimpleReceiverBase(IPoolAddressesProvider(_provider)) {}

    function executeOperation(
        address asset,
        uint256 amount,
        uint256 premium,
        address initiator,
        bytes calldata params
    ) external override returns (bool) {
        // Liquidate the NFT position
        // params should include the NFT and loan target
        (address borrower, uint256 tokenId) = abi.decode(params, (address, uint256));

        // Trigger liquidation on BendDAO / Paraspace
        // (Call the liquidation function of the protocol)
        // You can add an interface and call here

        // Sell NFT instantly on external market
        IERC721 nft = IERC721(liquidationTarget);
        nft.approve(nftMarketplace, tokenId);

        // TODO: Add logic to sell NFT via marketplace (e.g., Seaport or custom)

        // Repay flash loan
        uint256 totalDebt = amount + premium;
        IERC20(asset).approve(address(POOL), totalDebt);

        return true;
    }

    function requestFlashLoan(
        address token,
        uint256 amount,
        address borrower,
        uint256 tokenId
    ) external onlyOwner {
        bytes memory params = abi.encode(borrower, tokenId);
        POOL.flashLoanSimple(address(this), token, amount, params, 0);
    }

    function updateTargets(address _liquidationTarget, address _marketplace) external onlyOwner {
        liquidationTarget = _liquidationTarget;
        nftMarketplace = _marketplace;
    }
}
