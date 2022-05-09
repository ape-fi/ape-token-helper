// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/CTokenInterface.sol";

contract CTokenHelper is Ownable {
    using SafeERC20 for IERC20;

    /**
     * @notice Emitted when tokens are seized
     */
    event TokenSeized(address token, uint256 amount);

    /**
     * @notice Emitted when users call mintBorrow
     */
    event MintBorrow(
        CTokenInterface cTokenMint,
        uint256 mintAmount,
        CTokenInterface cTokenBorrow,
        uint256 borrowAmount
    );

    /**
     * @notice Emitted when users call repayRedeem
     */
    event RepayRedeem(
        CTokenInterface cTokenRepay,
        uint256 repayAmount,
        CTokenInterface cTokenRedeem,
        uint256 redeemTokens,
        uint256 redeemAmount
    );

    /**
     * @notice The sender mints and borrows.
     * @param cTokenMint The market that user wants to mint
     * @param mintAmount The mint amount
     * @param cTokenBorrow The market that user wants to borrow
     * @param borrowAmount The borrow amount
     */
    function mintBorrow(
        CTokenInterface cTokenMint,
        uint256 mintAmount,
        CTokenInterface cTokenBorrow,
        uint256 borrowAmount
    ) external {
        address underlying = cTokenMint.underlying();

        // Get funds from user.
        IERC20(underlying).safeTransferFrom(
            msg.sender,
            address(this),
            mintAmount
        );

        // Mint and borrow.
        IERC20(underlying).approve(address(cTokenMint), mintAmount);
        require(cTokenMint.mint(msg.sender, mintAmount) == 0, "mint failed");
        require(
            cTokenBorrow.borrow(payable(msg.sender), borrowAmount) == 0,
            "borrow failed"
        );

        emit MintBorrow(cTokenMint, mintAmount, cTokenBorrow, borrowAmount);
    }

    /**
     * @notice The sender repays and redeems.
     * @param cTokenRepay The market that user wants to repay
     * @param repayAmount The repay amount
     * @param cTokenRedeem The market that user wants to redeem
     * @param redeemTokens The number of cTokens to redeem into underlying
     * @param redeemAmount The amount of underlying to receive from redeeming cTokens
     */
    function repayRedeem(
        CTokenInterface cTokenRepay,
        uint256 repayAmount,
        CTokenInterface cTokenRedeem,
        uint256 redeemTokens,
        uint256 redeemAmount
    ) external {
        address underlying = cTokenRepay.underlying();

        // Get funds from user.
        IERC20(underlying).safeTransferFrom(
            msg.sender,
            address(this),
            repayAmount
        );

        // Repay and redeem.
        IERC20(underlying).approve(address(cTokenRepay), repayAmount);
        require(
            cTokenRepay.repayBorrow(msg.sender, repayAmount) == 0,
            "repay failed"
        );
        require(
            cTokenRedeem.redeem(
                payable(msg.sender),
                redeemTokens,
                redeemAmount
            ) == 0,
            "redeem failed"
        );

        emit RepayRedeem(
            cTokenRepay,
            repayAmount,
            cTokenRedeem,
            redeemTokens,
            redeemAmount
        );
    }

    /*** Admin functions ***/

    /**
     * @notice Seize tokens in this contract.
     * @param token The token
     * @param amount The amount
     */
    function seize(address token, uint256 amount) external onlyOwner {
        IERC20(token).safeTransfer(owner(), amount);
        emit TokenSeized(token, amount);
    }
}
