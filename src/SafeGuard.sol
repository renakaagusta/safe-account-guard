// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "safe-contracts/contracts/base/GuardManager.sol";
import "safe-contracts/contracts/examples/guards/BaseGuard.sol";
import {ITransactionGuard} from "safe-contracts/contracts/base/GuardManager.sol";
import {IModuleGuard} from "safe-contracts/contracts/base/ModuleManager.sol";
import {IERC165} from "safe-contracts/contracts/interfaces/IERC165.sol";

contract SafeGuard is BaseGuard {
    address public owner;
    address public serviceManager;
    mapping(address => mapping(bytes4 => bool)) public allowedFunctions;
    
    event FunctionAllowed(address indexed target, bytes4 indexed functionSelector);
    event FunctionRemoved(address indexed target, bytes4 indexed functionSelector);
    
    constructor(address _serviceManager) {
        owner = msg.sender;
        serviceManager = _serviceManager;
    }
    
    modifier onlyServiceManager() {
        require(msg.sender == owner, "Not authorized");
        _;
    }
    
    // Add contract to allowlist
    function allowFunction(address target, bytes4 functionSelector) external onlyServiceManager {
        allowedFunctions[target][functionSelector] = true;
        emit FunctionAllowed(target, functionSelector);
    }
    
    // Remove contract from allowlist
    function removeFunction(address target, bytes4 functionSelector) external onlyServiceManager {
        allowedFunctions[target][functionSelector] = false;
        emit FunctionRemoved(target, functionSelector);
    }
    
    // Check if transaction is going to an allowed contract
    function checkTransaction(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation,
        uint256 safeTxGas,
        uint256 baseGas,
        uint256 gasPrice,
        address gasToken,
        address payable refundReceiver,
        bytes memory signatures,
        address msgSender
    ) external view override {
        // Get function selector from data
        bytes4 functionSelector;
        if (data.length >= 4) {
            assembly {
                // Load first 32 bytes of the data
                let selector := mload(add(data, 32))
                // Take first 4 bytes
                functionSelector := and(selector, 0xFFFFFFFF00000000000000000000000000000000000000000000000000000000)
            }
        }
        require(allowedFunctions[to][functionSelector], "Function not allowed");
    }
    
    // No special checks after execution
    function checkAfterExecution(bytes32 txHash, bool success) external pure override {}

    function supportsInterface(bytes4 interfaceId) external pure override returns (bool) {
        return
            interfaceId == type(ITransactionGuard).interfaceId || // 0xe6d7a83a
            interfaceId == type(IModuleGuard).interfaceId || // 0x58401ed8
            interfaceId == type(IERC165).interfaceId; // 0x01ffc9a7
    }

    // For module-initiated transactions (no owner signatures needed)
    function checkModuleTransaction(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation,
        address module
    ) external returns (bytes32 moduleTxHash) {
        return bytes32(0);
    }

    function checkAfterModuleExecution(bytes32 txHash, bool success) external override {
    }
}
