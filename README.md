# Quarry Paymaster

## Concepts

### Paymaster

- The world acts as an ERC4337 paymaster. Currently it's compatible with EntryPoint 0.7.
- The paymaster pays for user operations using a combination of the user's allowance and balance:
  - First, it attempts to pay from the user's allowance
  - If the allowance is insufficient, it falls back to using the user's balance
  - If both are insufficient, the operation is rejected
- After paying for the user operation, any unused funds are returned to their respective sources (allowance or balance)
- See [`PaymasterSystem.sol`](./packages/contracts/src/namespaces/root/systems/PaymasterSystem.sol).

### Allowance

- Allowances are the primary source of funds for paying user operations
- If the allowance is insufficient, the paymaster will attempt to take the missing funds from the user's balance
- Allowances are granted and can only be spent on gas - they cannot be withdrawn or converted to withdrawable balance

### Balance

- Users can maintain a balance in the paymaster contract, up to a maximum of 0.1 ETH
- The balance can be used as a fallback when paying for user operations if the allowance is insufficient
- Users can deposit to and withdraw from their balance at any time
- The advantage of maintaining a balance in the paymaster over a balance in individual accounts is that multiple spenders (i.e. session accounts) can share the same balance
- See [`BalanceSystem.sol`](./packages/contracts/src/namespaces/root/systems/BalanceSystem.sol)

### Grantor

- The paymaster's root namespace owner can give a grant allowance to to grantors. See [`AdminSystem.sol`](./packages/contracts/src/namespaces/root/systems/AdminSystem.sol).
- A grantor can grant allowance to users. The amount granted is deducted from the grantors grant allowance. See [`GrantSystem.sol`](./packages/contracts/src/namespaces/root/systems/GrantSystem.sol).

### Spender

- A user can register spender accounts, which can spend from the user's allowance. See [`SpenderSystem.sol`](./packages/contracts/src/namespaces/root/systems/SpenderSystem.sol).
- Only accounts without own balance can be registered as spender, since the spender will always use the user's allowance.
- A spender can register itself as spender for a user by using the `world.callWithSignature` entry path. The payload is the calldata to `world.registerSpender`, signed by the user. A valid registration call via callWithSignature can access the user's allowance before the spender is registered, to avoid the user having to ever send a transaction from their own account. See [`recoverCallWithSignature.sol`](./packages/contracts/src/namespaces/root/utils/recoverCallWithSignature.sol).

### Pass

- A grantor can create a pass, which allows a user holding the pass to claim allowance from the grantor's allowance in regular intervals.
- A grantor can issue their passes to users.
- Anyone can trigger the method to claim for a user.
- See [`PassSystem.sol`](./packages/contracts/src/namespaces/root/systems/PassSystem.sol).
