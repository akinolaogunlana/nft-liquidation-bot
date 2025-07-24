// SPDX-License-Identifier: MIT pragma solidity ^0.8.20;

import "@aave/core-v3/contracts/interfaces/IPool.sol"; import "@aave/core-v3/contracts/flashloan/interfaces/IFlashLoanSimpleReceiver.sol"; import "@openzeppelin/contracts/token/ERC721/IERC721.sol"; import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; import "@openzeppelin/contracts/access/Ownable.sol"; import "hardhat/console.sol";

interface IBendDAO { function liquidateERC721(address nftAsset, uint256 tokenId) external payable; }

contract LiquidationBot is IFlashLoanSimpleReceiver, Ownable { address public immutable pool; address public immutable WETH; IBendDAO public bendDAO; address public immutable blurMarketplace;

constructor(
    address _aavePool,
    address _weth,
    address _bendDao,
    address _blurMarketplace
) {
    pool = _aavePool;
    WETH = _weth;
    bendDAO = IBendDAO(_bendDao);
    blurMarketplace = _blurMarketplace;
}

function requestFlashLoan(uint256 amount, address nft, uint256 tokenId) external onlyOwner {
    bytes memory params = abi.encode(nft, tokenId);
    IPool(pool).flashLoanSimple(address(this), WETH, amount, params, 0);
}

function executeOperation(
    address asset,
    uint256 amount,
    uint256 premium,
    address initiator,
    bytes calldata params
) external override returns (bool) {
    require(msg.sender == pool, "Untrusted lender");
    require(initiator == address(this), "Not initiated by contract");

    (address nft, uint256 tokenId) = abi.decode(params, (address, uint256));

    // 1. Liquidate NFT on BendDAO
    IERC20(WETH).approve(address(bendDAO), amount);
    bendDAO.liquidateERC721{value: 0}(nft, tokenId);

    // 2. Transfer to Blur marketplace to sell
    IERC721(nft).approve(blurMarketplace, tokenId);

    // (Here, real resale logic on Blur would be triggered via off-chain or custom SDK call)

    // 3. Repay flash loan
    uint256 totalRepayment = amount + premium;
    IERC20(WETH).approve(pool, totalRepayment);

    return true;
}

receive() external payable {}

}

