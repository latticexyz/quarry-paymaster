# Quarry Paymaster

## Concepts

### Paymaster

- The world acts as an ERC4337 paymaster. Currently it's compatible with EntryPoint 0.7.
- The paymaster pays for user operations if the user has sufficient allowance. The allowance is tracked in the `Allowance` table. After paying for the user operation, the gas paid is deducted from the user's allowance.
- See [`PaymasterSystem.sol`](./packages/contracts/src/namespaces/root/systems/PaymasterSystem.sol).

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
