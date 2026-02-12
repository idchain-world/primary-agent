# Primary Agent Registry - Sepolia Deployment

**Date:** 2026-02-11
**Network:** Sepolia (Chain ID: 11155111)
**Compiler:** solc 0.8.28
**Deployer:** `0xF8e03bd4436371E0e2F7C02E529b2172fe72b4EF`

## Deployed Contracts

| Contract | Address | Type |
|----------|---------|------|
| PrimaryAgentRegistry (Implementation) | `0xe924d03daaf1AEcc39fDE1902551ce713812823b` | CREATE |
| PrimaryAgentRegistry (Proxy) | `0xFb684dB5A38454Fe39cB314E495C1f5e3a3620c1` | ERC1967Proxy |
| SelfRegistrar | `0xEbB9561Caa68009faf3D912334F7a3525a28F3B0` | CREATE |
| ERC1271Registrar | `0xE831BA71aF7440a628f0b54476ad914d51731d8f` | CREATE |
| OwnableRegistrar | `0xd180541E7aa7A0DD1ffF84C9Bd86Df7CEa8b7B4F` | CREATE |
| AccessControlRegistrar | `0x39cFac3b757134247018DF61F6aA52d11764CC5C` | CREATE |

## Transaction Hashes

| Transaction | Hash |
|-------------|------|
| Deploy Implementation | `0x08b9a355039b973a0d010c8466998b0ab6b23b80c204ed10492321201e49da48` |
| Deploy Proxy | `0x7dc3c61d8e9a445235b8bdd11eb5b77aee8cd9e154bb51b9d930a0428ad80ebf` |
| Deploy SelfRegistrar | `0x11df63686638aa86620e77d608f50ed71a9ae11d1a57d06aa36b2b185a743d99` |
| Deploy ERC1271Registrar | `0xe9d6ec386da950974317ad9f1adc9af6e748fcf711c0c70936218350cfe2742e` |
| Deploy OwnableRegistrar | `0x196801574fe044cbe35460334b73c13f3bfff8627c9a39104f8244cbd72feb83` |
| Deploy AccessControlRegistrar | `0xcafe29a88bd56dbefe103d8ddadbfd0c7fad60e97c19309a9901ca8ea8b5e752` |
| Grant REGISTRAR_ROLE (Self) | `0x225db7a3a85381b2e697a5c8949e0a0f5bd0d394f9239feb2aece2e032b2a63f` |
| Grant REGISTRAR_ROLE (ERC1271) | `0x925c147d28e18278857b15680e6235c1524dd84d241fc0dd7ae54184522c9c2a` |
| Grant REGISTRAR_ROLE (Ownable) | `0x2783be349d7066d59328d01acf6cd8b081ebc91d4d2c7d0729df91ae1461417e` |
| Grant REGISTRAR_ROLE (AccessControl) | `0xe11bad3e895a4ad0e9076917e70187b66f511965f0f62814dea5d5cbe08cc23d` |

## Configuration

- Admin (DEFAULT_ADMIN_ROLE): `0xF8e03bd4436371E0e2F7C02E529b2172fe72b4EF`
- All four registrars granted REGISTRAR_ROLE
- Deployment mode: UUPS Proxy (upgradeable)

## Test Results

37 tests passing before deployment (4 test suites).
