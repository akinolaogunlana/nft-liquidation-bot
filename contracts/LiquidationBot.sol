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
    function sellNFT(address nftAsset, uint256 tokenId, uint256 minPrice) external;
}

contract LiquidationBot is IFlashLoanSimpleReceiver, Ownable {
    address public immutable pool;
    address public immutable WETH;
    IBendDAO public bendDAO;
    IBlurMarketplace public blurMarketplace;

    event FlashLoanRequested(uint256 amount, address nft, uint256 tokenId);
    event LiquidationExecuted(address nft, uint256 tokenId);
    event NFTListedForSale(address nft, uint256 tokenId);
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

    /// @notice Initiate flash loan to begin liquidation
    function requestFlashLoan(uint256 amount, address nft, uint256 tokenId) external onlyOwner {
        bytes memory params = abi.encode(nft, tokenId);
        emit FlashLoanRequested(amount, nft, tokenId);
        IPool(pool).flashLoanSimple(address(this), WETH, amount, params, 0);
    }

    /// @notice Aave Flash Loan callback
    function executeOperation(
        address asset,
        uint256 amount,
        uint256 premium,
        address initiator,
        bytes calldata params
    ) external override returns (bool) {
        require(msg.sender == pool, "Untrusted pool");
        require(initiator == address(this), "Not self-initiated");

        (address nft, uint256 tokenId) = abi.decode(params, (address, uint256));

        // Step 1: Liquidate NFT from BendDAO
        IERC20(WETH).approve(address(bendDAO), amount);
        bendDAO.liquidateERC721{value: 0}(nft, tokenId);
        emit LiquidationExecuted(nft, tokenId);

        // Step 2: Approve and list NFT on Blur (simulate)
        IERC721(nft).approve(address(blurMarketplace), tokenId);
        blurMarketplace.sellNFT(nft, tokenId, 0); // Placeholder: 0 = accept any price
        emit NFTListedForSale(nft, tokenId);

        // Step 3: Repay flash loan
        uint256 totalRepayment = amount + premium;
        IERC20(WETH).approve(pool, totalRepayment);
        emit FlashLoanRepaid(totalRepayment);

        return true;
    }

    /// @notice Receive ETH fallback
    receive() external payable {}
}