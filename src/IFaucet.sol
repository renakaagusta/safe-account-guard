// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IFaucet {
    // Events
    event AddToken(address token);
    event UpdateFaucetAmount(uint256 amount);
    event UpdateFaucetCooldown(uint256 cooldown);
    event RequestToken(address requester, address receiver, address token);
    event DepositToken(address depositor, address token, uint256 amount);

    // View Functions
    function owner() external view returns (address);
    function availableTokens(uint256) external view returns (address);
    function faucetAmount() external view returns (uint256);
    function faucetCooldown() external view returns (uint256);
    function lastRequestTime(address) external view returns (uint256);
    function getAvailableTokensLength() external view returns (uint256);
    function getLastRequestTime() external view returns (uint256);
    function getAvailabilityTime() external view returns (uint256);
    function getCooldown() external view returns (uint256);
    function getCurrentTimestamp() external view returns (uint256);

    // State-Changing Functions
    function addToken(address _token) external;
    function updateFaucetAmount(uint256 _faucetAmount) external;
    function updateFaucetCooldown(uint256 _faucetCooldown) external;
    function requestToken(address _receiver, address _token) external;
    function depositToken(address _token, uint256 _amount) external;
}