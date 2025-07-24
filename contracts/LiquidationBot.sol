// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@aave/core-v3/contracts/interfaces/IPool.sol";
import "@aave/core-v3/contracts/flashloan/interfaces/IFlashLoanSimpleReceiver.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IBendDAO {
    function liquidateERC721(address nftAsset, uint256 tokenId) external payable;
}

interface IBlurMarketplace {
    function sellNFT(address nft, uint256 tokenId, uint256 minPrice) external;
}

contract LiquidationBot is IFlashLoanSimpleReceiver, Ownable {
    // Immutable addresses for flash loan and token contracts
    address public immutable pool;
    address public immutable WETH;

    // Protocol interfaces
    IBendDAO public bendDAO;
    IBlurMarketplace public blurMarketplace;

    // Events for logging
    event FlashLoanRequested(uint256 amount, address nft, uint256 tokenId);
    event LiquidationSuccessful(address nft, uint256 tokenId);
    event NFTSold(address nft, uint256 tokenId, uint256 price);
    event FlashLoanRepaid(uint256 totalRepayment);

    constructor(
        address _aavePool,
        address _weth,
        address _bendDao,
        address _blurMarketplace
    ) {
        pool = _aavePool;
        WETH = _weth;
        bendDAO = IBendDAO(_bendDao);
        blurMarketplace = IBlurMarketplace(_blurMarketplace);
    }

    /// @notice Trigger the flash loan to liquidate an NFT
    function requestFlashLoan(uint256 amount, address nft, uint256 tokenId) external onlyOwner {
        bytes memory params = abi.encode(nft, tokenId);
        emit FlashLoanRequested(amount, nft, tokenId);
        IPool(pool).flashLoanSimple(address(this), WETH, amount, params, 0);
    }

    /// @notice Aave callback that executes once the flash loan is granted
    function executeOperation(
        address asset,
        uint256 amount,
        uint256 premium,
        address initiator,
        bytes calldata params
    ) external override returns (bool) {
        require(msg.sender == pool, "Unauthorized caller");
        require(initiator == address(this), "Invalid initiator");
        require(asset == WETH, "Unsupported asset");

        (address nft, uint256 tokenId) = abi.decode(params, (address, uint256));

        // 1. Liquidate the NFT on BendDAO
        IERC20(WETH).approve(address(bendDAO), amount);
        bendDAO.liquidateERC721{value: 0}(nft, tokenId);
        emit LiquidationSuccessful(nft, tokenId);

        // 2. Sell the NFT on Blur (off-chain logic or oracle driven)
        IERC721(nft).approve(address(blurMarketplace), tokenId);
        uint256 minPrice = amount + premium + 1e15; // + safety margin
        blurMarketplace.sellNFT(nft, tokenId, minPrice);
        emit NFTSold(nft, tokenId, minPrice);

        // 3. Repay the flash loan
        uint256 totalRepayment = amount + premium;
        IERC20(WETH).approve(pool, totalRepayment);
        emit FlashLoanRepaid(totalRepayment);

        return true;
    }

    receive() external payable {}
}
