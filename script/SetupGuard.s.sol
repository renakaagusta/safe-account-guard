// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "safe-contracts/contracts/Safe.sol";
import "../src/SafeGuard.sol";
import "safe-contracts/contracts/base/GuardManager.sol";
contract SetupGuard is Script {
    address SAFE_ADDRESS = vm.envAddress("SAFE_ADDRESS");
    address FAUCET_ADDRESS = vm.envAddress("FAUCET_ADDRESS");
    address USDT_ADDRESS = vm.envAddress("USDT_ADDRESS");
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

        console.log("Guard deployed at:", address(guard));
        
        // Allow the safe contract
        guard.allowContract(address(safe));

        // Allow the guard contract
        guard.allowContract(address(guard));

        // Allow the faucet contract
        guard.allowContract(FAUCET_ADDRESS);

        // Allow the USDT contract
        guard.allowContract(USDT_ADDRESS);

        // Allow the IDRT contract
        guard.allowContract(IDRT_ADDRESS);

        // Check threshold
        uint256 threshold = safe.getThreshold();
        require(ownerPrivateKeys.length >= threshold, "Not enough signers provided");
        
        // Create setGuard transaction data
        bytes memory guardData = abi.encodeCall(GuardManager.setGuard, (address(guard)));

        // Execute the setGuard transaction through multi-sig
        executeTransactionWithMultiSig(
            safe,
            SAFE_ADDRESS,  // calling the Safe itself
            0,            // no ETH value
            guardData,
            ownerPrivateKeys,
            threshold
        );

        vm.stopBroadcast();
    }

    function executeTransactionWithMultiSig(
        Safe safe,
        address to,
        uint256 value,
        bytes memory data,
        uint256[] memory privateKeys,
        uint256 threshold
    ) internal {
        uint256 safeTxGas = 0;
        uint256 baseGas = 0;
        uint256 gasPrice = 0;
        address gasToken = address(0);
        address payable refundReceiver = payable(address(0));

        // Generate transaction hash
        bytes32 txHash = safe.getTransactionHash(
            to,
            value,
            data,
            Enum.Operation.Call,
            safeTxGas,
            baseGas,
            gasPrice,
            gasToken,
            refundReceiver,
            safe.nonce()
        );

        // Collect signatures from owners
        bytes memory signatures = "";
        
        // Sort owners by address (required by Safe)
        (uint256[] memory sortedKeys, address[] memory sortedOwners) = sortOwnersByAddress(privateKeys);

        // Collect required number of signatures
        for(uint i = 0; i < threshold; i++) {
            (uint8 v, bytes32 r, bytes32 s) = vm.sign(sortedKeys[i], txHash);
            signatures = abi.encodePacked(signatures, abi.encodePacked(r, s, v));
        }

        // Execute transaction
        bool success = safe.execTransaction(
            to,
            value,
            data,
            Enum.Operation.Call,
            safeTxGas,
            baseGas,
            gasPrice,
            gasToken,
            refundReceiver,
            signatures
        );

        require(success, "Transaction execution failed");
    }

    // Helper function to sort owners by address (required by Safe)
    function sortOwnersByAddress(uint256[] memory privateKeys) internal view returns (uint256[] memory, address[] memory) {
        uint256 len = privateKeys.length;
        uint256[] memory sortedKeys = new uint256[](len);
        address[] memory sortedOwners = new address[](len);
        
        // Initialize arrays
        for(uint i = 0; i < len; i++) {
            sortedKeys[i] = privateKeys[i];
            sortedOwners[i] = vm.addr(privateKeys[i]);
        }
        
        // Bubble sort
        for(uint i = 0; i < len; i++) {
            for(uint j = 0; j < len - 1 - i; j++) {
                if(sortedOwners[j] > sortedOwners[j + 1]) {
                    // Swap addresses
                    address tempAddr = sortedOwners[j];
                    sortedOwners[j] = sortedOwners[j + 1];
                    sortedOwners[j + 1] = tempAddr;
                    
                    // Swap keys
                    uint256 tempKey = sortedKeys[j];
                    sortedKeys[j] = sortedKeys[j + 1];
                    sortedKeys[j + 1] = tempKey;
                }
            }
        }
        
        return (sortedKeys, sortedOwners);
    }
}