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
        _mint(cTokenMint, mintAmount);

        require(
            cTokenBorrow.borrow(payable(msg.sender), borrowAmount) == 0,
            "borrow failed"
        );
    }

    /**
     * @notice The sender mints.
     * @param cTokenMint The market that user wants to mint
     * @param mintAmount The mint amount
     */
    function mint(CTokenInterface cTokenMint, uint256 mintAmount) external {
        _mint(cTokenMint, mintAmount);
    }

    function _mint(CTokenInterface cTokenMint, uint256 mintAmount) internal {
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
        _repay(cTokenRepay, repayAmount);

        require(
            cTokenRedeem.redeem(
                payable(msg.sender),
                redeemTokens,
                redeemAmount
            ) == 0,
            "redeem failed"
        );
    }

    /**
     * @notice The sender repays.
     * @param cTokenRepay The market that user wants to repay
     * @param repayAmount The repay amount
     */
    function repay(CTokenInterface cTokenRepay, uint256 repayAmount) external {
        _repay(cTokenRepay, repayAmount);
    }

    function _repay(CTokenInterface cTokenRepay, uint256 repayAmount) internal {
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
