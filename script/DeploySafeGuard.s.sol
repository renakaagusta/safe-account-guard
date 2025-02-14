// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "safe-contracts/contracts/Safe.sol";
import "../src/SafeGuard.sol";
import "safe-contracts/contracts/base/GuardManager.sol";
import "../src/IFaucet.sol";
import "../src/IERC20.sol";

contract SetupGuard is Script {
    address SAFE_ADDRESS = vm.envAddress("SAFE_ADDRESS");
    address FAUCET_ADDRESS = vm.envAddress("FAUCET_ADDRESS");
    address IDRT_ADDRESS = vm.envAddress("IDRT_ADDRESS");

    // Array of owner private keys (from .env file)
    function getOwnerPrivateKeys() internal view returns (uint256[] memory) {
        uint256[] memory privateKeys = new uint256[](2);
        
        for(uint i = 1; i <= 2; i++) {
            privateKeys[i-1] = vm.envUint(string.concat("PRIVATE_KEY_", vm.toString(i)));
        }
        
        return privateKeys;
    }

    function run() external {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY_1"));

        uint256[] memory ownerPrivateKeys = getOwnerPrivateKeys();
        Safe safe = Safe(payable(SAFE_ADDRESS));
        
        // Deploy the guard
        SafeGuard guard = new SafeGuard();
        
        guard.updateServiceManager(vm.envAddress("SERVICE_MANAGER_ADDRESS"));

        console.log("Guard deployed at:", address(guard));
    }
}