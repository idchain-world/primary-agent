# Primary Agent Registry

A singleton registry that links each Ethereum address to a single agent identity, enabling any address to be resolved to the agent it represents. Deployed once per chain as a single authoritative source for address-to-agent resolution.

## Overview

The Primary Agent Registry maps each Ethereum address to a packed `bytes` value encoding the agent registry address and token ID:

```
20 bytes: registry address | 1 byte: ID length | N bytes: token ID
```

For token IDs up to 10 bytes (2^80), the entire value fits in **a single storage slot**.

```solidity
(address registry, uint256 tokenId) = primaryAgentRegistry.resolveAgentId(someAddress);
// registry = 0xAgentRegistry, tokenId = 42
```

## Architecture

```
┌──────────────────────────────────────────┐
│         PrimaryAgentRegistry             │
│          (Singleton Registry)            │
│                                          │
│  mapping(address => bytes)               │
│  bytes = [20B registry][1B len][NB id]   │
│                                          │
│  + register()        (REGISTRAR_ROLE)    │
│  + resolveAgentId()  (public view)       │
│  + agentData()       (public view)       │
└──────────────────┬───────────────────────┘
                   │ REGISTRAR_ROLE
     ┌─────────────┼─────────────┬─────────────┬─────────────┐
     │             │             │             │             │
┌────┴────┐ ┌─────┴─────┐ ┌────┴────┐ ┌──────┴──────┐ ┌────┴────┐
│  Self   │ │  ERC-1271 │ │ Ownable │ │ Role-check  │ │ Signed  │
│Registrar│ │ Registrar │ │Registrar│ │  Registrar  │ │Registrar│
└─────────┘ └───────────┘ └─────────┘ └─────────────┘ └─────────┘
```

## Registrars

| Registrar | Use Case | Verification Method |
|-----------|----------|-------------------|
| **SelfRegistrar** | EOAs registering themselves | `msg.sender` is the account |
| **ERC1271Registrar** | Smart contract wallets | ERC-1271 `isValidSignature()` |
| **OwnableRegistrar** | Contracts with `owner()` | Calls `owner()` or `getOwner()` |
| **AccessControlRegistrar** | Contracts with role-based access | Calls `hasRole(adminRole, caller)` |
| **SignedRegistrar** | EOAs via off-chain signature | ECDSA `ecrecover` (EIP-191 `personal_sign`) |

## Getting Started

### Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation)

### Build

```bash
forge build
```

### Test

```bash
forge test
```

## Usage

### Register an EOA (Self Registrar)

```solidity
SelfRegistrar selfRegistrar = SelfRegistrar(SELF_REGISTRAR_ADDRESS);

// Register your address with agent registry and token ID
selfRegistrar.register(agentRegistryAddress, tokenId);

// Clear registration
selfRegistrar.register(address(0), 0);
```

### Register an EOA via Signature (Signed Registrar)

```solidity
SignedRegistrar signedRegistrar = SignedRegistrar(SIGNED_REGISTRAR_ADDRESS);

// Off-chain: EOA signs the registration message (deadline 0 = no expiry)
uint256 deadline = block.timestamp + 1 hours; // or 0 for no expiry
bytes32 hash = keccak256(abi.encodePacked(account, registry, tokenId, deadline, chainId, signedRegistrarAddress, nonce));
bytes32 ethHash = MessageHashUtils.toEthSignedMessageHash(hash);
(uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, ethHash); // or wallet.signMessage()

// On-chain: anyone can submit the signature
signedRegistrar.register(account, agentRegistryAddress, tokenId, deadline, abi.encodePacked(r, s, v));
```

### Register a Smart Contract (ERC-1271)

```solidity
ERC1271Registrar erc1271Registrar = ERC1271Registrar(ERC1271_REGISTRAR_ADDRESS);

// The smart contract wallet must validate the signature
erc1271Registrar.register(walletAddress, agentRegistryAddress, tokenId, signature);
```

### Register an Ownable Contract

```solidity
OwnableRegistrar ownableRegistrar = OwnableRegistrar(OWNABLE_REGISTRAR_ADDRESS);

// Must be called by the contract's owner
ownableRegistrar.register(contractAddress, agentRegistryAddress, tokenId);
```

### Resolve an Address

```solidity
PrimaryAgentRegistry primaryAgentRegistry = PrimaryAgentRegistry(PRIMARY_AGENT_ADDRESS);

// Resolve: address -> (registry, tokenId)
(address registry, uint256 tokenId) = primaryAgentRegistry.resolveAgentId(someAddress);

// Check registration status
bool registered = primaryAgentRegistry.isRegistered(someAddress);

// Get raw packed bytes
bytes memory data = primaryAgentRegistry.agentData(someAddress);
```

## Storage Encoding

```
Token ID 42:    [20B registry][0x01][0x2a]                = 22 bytes (1 slot)
Token ID 256:   [20B registry][0x02][0x01][0x00]          = 23 bytes (1 slot)
Token ID 0:     [20B registry][0x00]                      = 21 bytes (1 slot)
Token ID 2^80:  [20B registry][0x0a][10 bytes...]         = 31 bytes (1 slot)
Token ID 2^256: [20B registry][0x20][32 bytes...]         = 53 bytes (2 slots)
```

## Admin Operations

The deployer receives the admin role and can manage registrars:

```solidity
// Grant REGISTRAR_ROLE to a new registrar contract
primaryAgentRegistry.grantRole(REGISTRAR_ROLE, newRegistrarAddress);

// Revoke REGISTRAR_ROLE
primaryAgentRegistry.revokeRole(REGISTRAR_ROLE, oldRegistrarAddress);
```

## Contract Addresses

### Sepolia (Chain ID: 11155111)

| Contract | Address |
|----------|---------|
| PrimaryAgentRegistry (Proxy) | `0xFb684dB5A38454Fe39cB314E495C1f5e3a3620c1` |
| PrimaryAgentRegistry (Implementation) | `0xe924d03daaf1AEcc39fDE1902551ce713812823b` |
| SelfRegistrar | `0xEbB9561Caa68009faf3D912334F7a3525a28F3B0` |
| ERC1271Registrar | `0xE831BA71aF7440a628f0b54476ad914d51731d8f` |
| OwnableRegistrar | `0xd180541E7aa7A0DD1ffF84C9Bd86Df7CEa8b7B4F` |
| AccessControlRegistrar | `0x39cFac3b757134247018DF61F6aA52d11764CC5C` |
| SignedRegistrar | `0x8C6E4dDeCc8ec13E6cbE34634f61656f7CB91999` |

### Base (Chain ID: 8453)

| Contract | Address |
|----------|---------|
| PrimaryAgentRegistry (Proxy) | `0xeC8554c3Ff5B986a6F631c402d281E27a7a42b5C` |
| PrimaryAgentRegistry (Implementation) | `0x090323AE9BD72E85BFbEA346bD9c9f24BbEE9AF8` |
| SelfRegistrar | `0x6F48C14C0C8426560B2b64240D17dB5f4F96FB27` |
| ERC1271Registrar | `0xABB1993b9eA0E15C10cC112C334CA21F4643dc55` |
| OwnableRegistrar | `0x96Def5706e2Cd957e347945C680d1d0f7bCc9184` |
| AccessControlRegistrar | `0x6F0f16F965A8885eA8E128A96b7d977375aa4468` |
| SignedRegistrar | `0x474E2193c25F74C824819ffCb60572fC0Ea00358` |

## License

MIT
