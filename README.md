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