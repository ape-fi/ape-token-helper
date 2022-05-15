// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../interfaces/ComptrollerInterface.sol";

contract MockComptroller is ComptrollerInterface {
    mapping(address => bool) isListed;

    function supportMarket(address apeTokenAddress) external {
        isListed[apeTokenAddress] = true;
    }

    function isMarketListed(address apeTokenAddress)
        external
        view
        returns (bool)
    {
        return isListed[apeTokenAddress];
    }
}
