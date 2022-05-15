// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../interfaces/ApeTokenInterface.sol";

contract MockApeToken is ApeTokenInterface {
    using SafeERC20 for IERC20;

    mapping(address => uint256) private _balance;
    address private _underlying;
    uint256 private _exchangeRate;
    mapping(address => uint256) private _borrowBalance;
    bool private mintFailed;
    bool private borrowFailed;
    bool private redeemFailed;
    bool private repayFailed;

    constructor(address underlying_) {
        _underlying = underlying_;
    }

    function underlying() external view returns (address) {
        return _underlying;
    }

    function setExchangeRateStored(uint256 exchangeRate_) external {
        _exchangeRate = exchangeRate_;
    }

    function exchangeRateStored() external view returns (uint256) {
        return _exchangeRate;
    }

    function borrowBalanceStored(address account)
        public
        view
        returns (uint256)
    {
        return _borrowBalance[account];
    }

    function balanceOf(address account) external view returns (uint256) {
        return _balance[account];
    }

    function setMintFailed() external {
        mintFailed = true;
    }

    function mint(address minter, uint256 mintAmount)
        external
        returns (uint256)
    {
        if (mintFailed) {
            return 1; // Return non-zero to simulate graceful failure.
        }

        IERC20(_underlying).safeTransferFrom(
            msg.sender,
            address(this),
            mintAmount
        );
        uint256 amount = (mintAmount * _exchangeRate) / 1e18;
        _balance[minter] += amount;
        return 0;
    }

    function mintNative(address minter) external payable returns (uint256) {
        if (mintFailed) {
            return 1; // Return non-zero to simulate graceful failure.
        }

        uint256 amount = (msg.value * _exchangeRate) / 1e18;
        _balance[minter] += amount;
        return 0;
    }

    function setBorrowFailed() external {
        borrowFailed = true;
    }

    function borrow(address payable borrower, uint256 borrowAmount)
        external
        returns (uint256)
    {
        if (borrowFailed) {
            return 1; // Return non-zero to simulate graceful failure.
        }

        _borrowBalance[borrower] += borrowAmount;
        IERC20(_underlying).safeTransfer(borrower, borrowAmount);
        return 0;
    }

    function borrowNative(address payable borrower, uint256 borrowAmount)
        external
        returns (uint256)
    {
        if (borrowFailed) {
            return 1; // Return non-zero to simulate graceful failure.
        }

        _borrowBalance[borrower] += borrowAmount;
        borrower.transfer(borrowAmount);
        return 0;
    }

    function setRedeemFailed() external {
        redeemFailed = true;
    }

    function redeem(
        address payable redeemer,
        uint256 redeemTokens,
        uint256 redeemAmount
    ) external returns (uint256) {
        if (redeemFailed) {
            return 1; // Return non-zero to simulate graceful failure.
        }

        if (redeemAmount != 0) {
            uint256 tokens = (redeemAmount * _exchangeRate) / 1e18;
            _balance[redeemer] -= tokens;
            IERC20(_underlying).safeTransfer(redeemer, redeemAmount);
        } else {
            _balance[redeemer] -= redeemTokens;
            uint256 amount = (redeemTokens * 1e18) / _exchangeRate;
            IERC20(_underlying).safeTransfer(redeemer, amount);
        }
        return 0;
    }

    function redeemNative(
        address payable redeemer,
        uint256 redeemTokens,
        uint256 redeemAmount
    ) external returns (uint256) {
        if (redeemFailed) {
            return 1; // Return non-zero to simulate graceful failure.
        }

        if (redeemAmount != 0) {
            uint256 tokens = (redeemAmount * _exchangeRate) / 1e18;
            _balance[redeemer] -= tokens;
            redeemer.transfer(redeemAmount);
        } else {
            _balance[redeemer] -= redeemTokens;
            uint256 amount = (redeemTokens * 1e18) / _exchangeRate;
            redeemer.transfer(amount);
        }
        return 0;
    }

    function setRepayFailed() external {
        repayFailed = true;
    }

    function repayBorrow(address borrower, uint256 repayAmount)
        external
        returns (uint256)
    {
        if (repayFailed) {
            return 1; // Return non-zero to simulate graceful failure.
        }

        _borrowBalance[borrower] -= repayAmount;
        IERC20(_underlying).safeTransferFrom(
            msg.sender,
            address(this),
            repayAmount
        );
        return 0;
    }

    function repayBorrowNative(address borrower)
        external
        payable
        returns (uint256)
    {
        if (repayFailed) {
            return 1; // Return non-zero to simulate graceful failure.
        }

        _borrowBalance[borrower] -= msg.value;
        return 0;
    }
}
