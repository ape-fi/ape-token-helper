// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ComptrollerInterface {
    function isMarketListed(address cTokenAddress) external view returns (bool);
}
