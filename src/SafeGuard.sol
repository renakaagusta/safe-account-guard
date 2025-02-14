// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "safe-contracts/contracts/base/GuardManager.sol";
import "safe-contracts/contracts/examples/guards/BaseGuard.sol";
import {ITransactionGuard} from "safe-contracts/contracts/base/GuardManager.sol";
import {IModuleGuard} from "safe-contracts/contracts/base/ModuleManager.sol";
import {IERC165} from "safe-contracts/contracts/interfaces/IERC165.sol";

interface IHelloWorldServiceManager {
    event NewTaskCreated(uint32 indexed taskIndex, Task task);

    event TaskResponded(uint32 indexed taskIndex, Task task, address operator);
    event Transaction(uint32 indexed taskIndex, address indexed from, address indexed to, uint256 value, bytes data, bytes message, bool status);
    struct Task {
        uint32 taskCreatedBlock;
        address from;
        address to;
        bytes data;
        uint256 value;
    }

    function latestTaskNum() external view returns (uint32);

    function allTaskHashes(
        uint32 taskIndex
    ) external view returns (bytes32);

    function allTaskResponses(
        address operator,
        uint32 taskIndex
    ) external view returns (bytes memory);

    function createNewTask(
        address from,
        address to,
        bytes memory data,
        uint256 value
    ) external returns (Task memory);

    function respondToTask(
        Task calldata task,
        uint32 referenceTaskIndex,
        bytes memory signature,
        bool isSafe,
        bytes memory causeHash
    ) external;
}

contract SafeGuard is BaseGuard {

    address public serviceManager;

    mapping(address => mapping(bytes4 => bool)) public allowedFunctions;
    mapping(address => mapping(bytes4 => bool)) public rejectedFunctions;
    mapping(address => mapping(bytes4 => bool)) public proposedFunctions;

    event FunctionAllowed(address indexed target, bytes4 indexed functionSelector);
    event FunctionRejected(address indexed target, bytes4 indexed functionSelector);
    event FunctionProposed(address indexed target, bytes4 indexed functionSelector);

    // Used for development purposes
    function updateServiceManager(address _serviceManager) external {
        serviceManager = _serviceManager;
    }
    
    modifier onlyServiceManager() {
        require(msg.sender == serviceManager, "Not authorized");
        _;
    }
    
    // Add contract to allowlist
    function allowFunction(address target, bytes4 functionSelector) external onlyServiceManager {
        proposedFunctions[target][functionSelector] = false;
        allowedFunctions[target][functionSelector] = true;
        emit FunctionAllowed(target, functionSelector);
    }

    // Remove contract from allowlist
    function rejectFunction(address target, bytes4 functionSelector) external onlyServiceManager {
        proposedFunctions[target][functionSelector] = false;
        rejectedFunctions[target][functionSelector] = true;
        emit FunctionRejected(target, functionSelector);
    }

    function proposeFunction(address target, bytes4 functionSelector) external onlyServiceManager {
        proposedFunctions[target][functionSelector] = true;
        emit FunctionProposed(target, functionSelector);
        IHelloWorldServiceManager(serviceManager).createNewTask(
            msg.sender, 
            target, 
            abi.encode(target, functionSelector),
            0
        );
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
    ) external override {
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
        
        require(rejectedFunctions[to][functionSelector] == false, "Function not allowed");
    
        // if (proposedFunctions[to][functionSelector] == false && allowedFunctions[to][functionSelector] == false) {
            proposedFunctions[to][functionSelector] = true;
            emit FunctionProposed(to, functionSelector);
            IHelloWorldServiceManager(serviceManager).createNewTask(
                msg.sender, 
                to, 
                abi.encode(to, functionSelector, data),
                0
            );
        // }
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
