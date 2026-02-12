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
     ┌─────────────┼─────────────┬─────────────┐
     │             │             │             │
┌────┴────┐ ┌─────┴─────┐ ┌────┴────┐ ┌──────┴──────┐
│  Self   │ │  ERC-1271 │ │ Ownable │ │ Role-check  │
│Registrar│ │ Registrar │ │Registrar│ │  Registrar  │
└─────────┘ └───────────┘ └─────────┘ └─────────────┘
```

## Registrars

| Registrar | Use Case | Verification Method |
|-----------|----------|-------------------|
| **SelfRegistrar** | EOAs registering themselves | `msg.sender` is the account |
| **ERC1271Registrar** | Smart contract wallets | ERC-1271 `isValidSignature()` |
| **OwnableRegistrar** | Contracts with `owner()` | Calls `owner()` or `getOwner()` |
| **AccessControlRegistrar** | Contracts with role-based access | Calls `hasRole(adminRole, caller)` |

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

Designed for singleton deployment via CREATE2 to the same address on every EVM chain.

| Chain | Address |
|-------|---------|
| TBD | TBD |

## License

MIT
