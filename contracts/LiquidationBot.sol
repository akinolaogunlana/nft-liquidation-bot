// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@aave/core-v3/contracts/flashloan/base/FlashLoanSimpleReceiverBase.sol";
import "@aave/core-v3/contracts/interfaces/IPoolAddressesProvider.sol";
import "@aave/core-v3/contracts/interfaces/IPool.sol";

interface IBendDAO {
    function liquidate(
        address nftAsset,
        uint256 tokenId
    ) external;
}

contract LiquidationBot is FlashLoanSimpleReceiverBase {
    address public owner;
    address public bendDao;
    address public nftAsset;
    uint256 public tokenId;

    constructor(address _addressProvider, address _bendDao)
        FlashLoanSimpleReceiverBase(IPoolAddressesProvider(_addressProvider))
    {
        owner = msg.sender;
        bendDao = _bendDao;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    function executeLiquidation(
        address _asset,
        uint256 _amount,
        address _nftAsset,
        uint256 _tokenId
    ) external onlyOwner {
        nftAsset = _nftAsset;
        tokenId = _tokenId;

        // Start flash loan
        POOL.flashLoanSimple(
            address(this), // Receiver
            _asset,        // Token to borrow
            _amount,       // Amount
            "",            // Params
            0              // Referral code
        );
    }

    function executeOperation(
        address asset,
        uint256 amount,
        uint256 premium,
        address initiator,
        bytes calldata
    ) external override returns (bool) {
        require(msg.sender == address(POOL), "Caller is not POOL");

        // Liquidate undercollateralized NFT on BendDAO
        IBendDAO(bendDao).liquidate(nftAsset, tokenId);

        // Repay flash loan
        uint256 totalOwed = amount + premium;
        IERC20(asset).approve(address(POOL), totalOwed);

        return true;
    }

    function withdrawToken(address token) external onlyOwner {
        IERC20(token).transfer(owner, IERC20(token).balanceOf(address(this)));
    }

    function withdrawNFT(address nft, uint256 _tokenId) external onlyOwner {
        IERC721(nft).transferFrom(address(this), owner, _tokenId);
    }
}