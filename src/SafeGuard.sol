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
    mapping(address => bool) public allowedContracts;
    
    event ContractAllowed(address indexed target);
    event ContractRemoved(address indexed target);
    
    constructor() {
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Not authorized");
        _;
    }
    
    // Add contract to allowlist
    function allowContract(address target) external onlyOwner {
        allowedContracts[target] = true;
        emit ContractAllowed(target);
    }
    
    // Remove contract from allowlist
    function removeContract(address target) external onlyOwner {
        allowedContracts[target] = false;
        emit ContractRemoved(target);
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
        require(allowedContracts[to], "Contract not allowed");
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
        // Add your implementation here
    }
}
