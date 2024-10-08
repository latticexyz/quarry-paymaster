# Quarry Paymaster Service

A minimal service to issue passes to users and claim allowances for users.

## API

### Issue Pass

Issue the given pass to the given user.

Namespace: `quarry`

Method: `issuePass`

Parameters: `[passId: bytes32, user: address]`

#### RPC

```bash
cast rpc quarry_issuePass 0x01 0xF58A647F89D70e275ead00D4F169176636274144 --rpc-url http://localhost:3003/rpc
```

#### REST

```bash
params='["0x01","0xF58A647F89D70e275ead00D4F169176636274144"]'
curl -G "http://localhost:3003/api/quarry/issuePass" --data-urlencode "params=$params"
```

### Claim Allowance

Claim allowance for a given user from a given pass.

Namespace: `quarry`

Method: `claimAllowance`

Parameters: `[user: address, passId: bytes32]`

#### RPC

```bash
cast rpc quarry_claimAllowance 0xF58A647F89D70e275ead00D4F169176636274144 0x01 --rpc-url http://localhost:3003/rpc
```

#### REST

```bash
params='["0xF58A647F89D70e275ead00D4F169176636274144","0x01"]'
curl -G "http://localhost:3003/api/quarry/claimAllowance" --data-urlencode "params=$params"
```
