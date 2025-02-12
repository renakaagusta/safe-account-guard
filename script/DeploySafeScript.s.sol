// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "safe-contracts/contracts/Safe.sol";
import "safe-contracts/contracts/proxies/SafeProxyFactory.sol";
import "safe-contracts/contracts/handler/CompatibilityFallbackHandler.sol";

contract DeploySafeScript is Script {
    function run() external {
        // Use private key for deployment
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Deploy Safe Singleton
        Safe safeSingleton = new Safe();

        // Deploy Safe Factory
        SafeProxyFactory safeFactory = new SafeProxyFactory();

         // Deploy Compatibility Fallback Handler
        CompatibilityFallbackHandler fallbackHandler = new CompatibilityFallbackHandler();

        // Setup Safe configuration
        address[] memory owners = new address[](2);
        owners[0] = vm.envAddress("ADDRESS_1"); 
        owners[1] = vm.envAddress("ADDRESS_2");

        uint256 threshold = 2;
        address to = address(0);
        bytes memory data = "";
        address paymentToken = address(0);
        uint256 payment = 0;
        address payable paymentReceiver = payable(address(0));

        // Generate Safe initialization data
        bytes memory initializer = abi.encodeWithSelector(
            Safe.setup.selector,
            owners,
            threshold,
            to,
            data,
            address(fallbackHandler),
            paymentToken,
            payment,
            paymentReceiver
        );

        // Deploy Safe Proxy
        address payable safe = payable(
            address(
                safeFactory.createProxyWithNonce(
                    address(safeSingleton),
                    initializer,
                    block.timestamp // Using timestamp as salt
                )
            )
        );

        console.log("Safe deployed at:", safe);

        vm.stopBroadcast();
    }
}