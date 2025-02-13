# Smart Account Contracts

This project demonstrates the implementation and usage of Safe Guard functionality with Safe (formerly Gnosis Safe) smart contracts. It showcases how to restrict and control which contracts a Safe wallet can interact with through a guard mechanism.

## Overview

The system consists of:
- Multi-signature Safe wallet with configurable threshold (2-of-2 by default)
- SafeGuard contract that acts as a security layer to control contract interactions
- Integration with a Faucet contract (from https://github.com/renakaagusta/faucet) as an example of guarded interaction
- Support for multiple ERC20 tokens (USDT, IDRT) to demonstrate token transfers through the guard

## Key Features

- **Guard Protection**: SafeGuard ensures transactions only go to whitelisted contracts, providing an additional security layer
- **Multi-signature Security**: Requires multiple signatures to execute transactions
- **Controlled Contract Interaction**: Demonstrates how to safely interact with external contracts (like the Faucet) through the guard
- **Token Management**: Shows how guarded token transfers and approvals work

## Prerequisites

1. Install Foundry
2. Copy `.env.example` to `.env` and fill in required values
3. Configure owner addresses and private keys in `.env`

## Deployment Steps

1. Deploy Safe contract

forge script script/DeploySafeScript.s.sol --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast

2. Transfer USDT to Safe contract

cast send --private-key $PRIVATE_KEY $USDT_ADDRESS "transfer(address,uint256)(bool)" $SAFE_ADDRESS 1000000000000000000000      

cast call --private-key $PRIVATE_KEY $USDT_ADDRESS "balanceOf(address)(uint256)" $SAFE_ADDRESS

3. Transfer IDRT to Safe contract

cast send --private-key $PRIVATE_KEY $IDRT_ADDRESS "transfer(address,uint256)(bool)" $SAFE_ADDRESS 1000000000000000000000  

cast call --private-key $PRIVATE_KEY $IDRT_ADDRESS "balanceOf(address)(uint256)" $SAFE_ADDRESS

4. Setup Guard

forge script script/SetupGuard.s.sol --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast

5. Approve Faucet contract

forge script script/FaucetApprove.s.sol --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast

6. Deposit to Faucet contract

forge script script/FaucetDeposit.s.sol --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast