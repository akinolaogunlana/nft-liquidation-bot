// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Aave v3 Flash Loan Interface
import "@aave/core-v3/contracts/interfaces/IPool.sol";
import "@aave/core-v3/contracts/flashloan/interfaces/IFlashLoanSimpleReceiver.sol";

// OpenZeppelin Contracts
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// For local testing/debugging
import "hardhat/console.sol";

// Interface for BendDAO NFT liquidation
interface IBendDAO {
    function liquidateERC721(address nftAsset, uint256 tokenId) external payable;
}

contract LiquidationBot is IFlashLoanSimpleReceiver, Ownable {
    address public immutable pool;           // Aave v3 Lending Pool
    address public immutable WETH;           // WETH Token
    IBendDAO public bendDAO;                 // BendDAO interface
    address public immutable blurMarketplace; // NFT resale marketplace

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

    /**
     * @dev Triggers the flash loan and NFT liquidation operation
     * @param amount Amount of WETH to borrow
     * @param nft NFT contract address
     * @param tokenId NFT token ID to liquidate
     */
    function requestFlashLoan(
        uint256 amount,
        address nft,
        uint256 tokenId
    ) external onlyOwner {
        bytes memory params = abi.encode(nft, tokenId);
        IPool(pool).flashLoanSimple(
            address(this),
            WETH,
            amount,
            params,
            0 // referralCode
        );
    }

    /**
     * @dev Aave calls this after flash loan is issued
     */
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

        console.log("Executing flash loan liquidation...");
        console.log("NFT: %s", nft);
        console.log("TokenID: %s", tokenId);

        // Approve WETH to BendDAO
        IERC20(WETH).approve(address(bendDAO), amount);

        // Perform NFT liquidation on BendDAO
        bendDAO.liquidateERC721{value: 0}(nft, tokenId);

        // Approve NFT for resale on Blur
        IERC721(nft).approve(blurMarketplace, tokenId);

        // NOTE: You should call resale logic off-chain via a bot or backend API to Blur
        // Example: via Seaport SDK or Blur API (currently off-chain)

        // Repay Aave flash loan
        uint256 totalRepayment = amount + premium;
        IERC20(WETH).approve(pool, totalRepayment);

        return true;
    }

    // To receive native ETH if needed
    receive() external payable {}
}
