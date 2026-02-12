# Primary Agent Registry - Base Deployment

**Date:** 2026-02-12
**Network:** Base (Chain ID: 8453)
**Compiler:** solc 0.8.28
**Deployer:** `0xF8e03bd4436371E0e2F7C02E529b2172fe72b4EF`

## Deployed Contracts

| Contract | Address |
|----------|---------|
| PrimaryAgentRegistry (Implementation) | `0x090323AE9BD72E85BFbEA346bD9c9f24BbEE9AF8` |
| PrimaryAgentRegistry (Proxy) | `0xeC8554c3Ff5B986a6F631c402d281E27a7a42b5C` |
| SelfRegistrar | `0x6F48C14C0C8426560B2b64240D17dB5f4F96FB27` |
| ERC1271Registrar | `0xABB1993b9eA0E15C10cC112C334CA21F4643dc55` |
| OwnableRegistrar | `0x96Def5706e2Cd957e347945C680d1d0f7bCc9184` |
| AccessControlRegistrar | `0x6F0f16F965A8885eA8E128A96b7d977375aa4468` |
| SignedRegistrar | `0x474E2193c25F74C824819ffCb60572fC0Ea00358` |

## Transaction Hashes

| Transaction | Hash |
|-------------|------|
| Deploy Implementation | `0x695223911e9220394d64b06063b1ddb2baa8a444d96e6ef09a63f16b1a9f34c8` |
| Deploy Proxy | `0x4cd28a2bcd91e7bec2a623b976599263083d9df482a57ecafee89fe29156fd10` |
| Deploy SelfRegistrar | `0x0c35d30fca8eca505a6f13ae8c94fedf6ae109380925263e4dfba326f207adae` |
| Deploy ERC1271Registrar | `0x5c49d5a18ca5fa7322162e6f0d794be7160b02c41220ce9cc1b0ef6cad99c4d4` |
| Deploy OwnableRegistrar | `0xa75b287f28c81746eb1ea99016ae395ad311f7724c7dbaf55fd3f09a0f72ea4d` |
| Deploy AccessControlRegistrar | `0xc56c52a3d6988dd16b3a5dc5c2d991e441ea3754ddf37d61309506458b78af61` |
| Deploy SignedRegistrar | `0x6449da12e69db5caed886414605ef7b315641e29e46f44a8043c1a617508e47c` |
| Grant REGISTRAR_ROLE (Self) | `0x6c9334d429b15a5c50c64ca5822a8cf53f6544886d25120137a97ebe39d9f929` |
| Grant REGISTRAR_ROLE (ERC1271) | `0x5c58ee987f0b8b70612d9677aa45c669f63bf28888a91eb4d90a12606bcdf34b` |
| Grant REGISTRAR_ROLE (Ownable) | `0xfc8498171c936b122dc5a6eeef25b9eb172acab6830948ab264c77d46b39b767` |
| Grant REGISTRAR_ROLE (AccessControl) | `0x05b2f083e0fb780b58e7980f90fbcc6d4428d6d8928217b7e7a4d68d4cff2e4b` |
| Grant REGISTRAR_ROLE (Signed) | `0x8dc108b74f4ac771f0b024ac0fe43a6232503ae93c9187b2e2c8cc1069400114` |

## Configuration

- Admin (DEFAULT_ADMIN_ROLE): `0xF8e03bd4436371E0e2F7C02E529b2172fe72b4EF`
- All five registrars granted REGISTRAR_ROLE
- Deployment mode: UUPS Proxy (upgradeable)
- Deploy script: `scripts/Deploy.s.sol`
- Broadcast: `broadcast/Deploy.s.sol/8453/run-latest.json`
- Block: 41,812,017 (`0x2818831`) — all 12 transactions in same block
- Verified on-chain: `hasRole(REGISTRAR_ROLE, signedRegistrar) == true`

## Test Results

46 tests passing (5 test suites).

---

# Previous Deployment: Primary Agent Registry - Sepolia

**Date:** 2026-02-11 (SignedRegistrar added 2026-02-12)
**Network:** Sepolia (Chain ID: 11155111)
**Compiler:** solc 0.8.28
**Deployer:** `0xF8e03bd4436371E0e2F7C02E529b2172fe72b4EF`

## Deployed Contracts

| Contract | Address |
|----------|---------|
| PrimaryAgentRegistry (Implementation) | `0xe924d03daaf1AEcc39fDE1902551ce713812823b` |
| PrimaryAgentRegistry (Proxy) | `0xFb684dB5A38454Fe39cB314E495C1f5e3a3620c1` |
| SelfRegistrar | `0xEbB9561Caa68009faf3D912334F7a3525a28F3B0` |
| ERC1271Registrar | `0xE831BA71aF7440a628f0b54476ad914d51731d8f` |
| OwnableRegistrar | `0xd180541E7aa7A0DD1ffF84C9Bd86Df7CEa8b7B4F` |
| AccessControlRegistrar | `0x39cFac3b757134247018DF61F6aA52d11764CC5C` |
| SignedRegistrar | `0x8C6E4dDeCc8ec13E6cbE34634f61656f7CB91999` |

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
| Deploy SignedRegistrar | `0x57633606caa62e3460f997ba6b8e8c785765960a5d1fe54299bc034629a72847` |
| Grant REGISTRAR_ROLE (Signed) | `0xb84877d30257fa4b3cf575f19fc65d730ef646ad9154722dd344240a1052b674` |

## Configuration

- Admin (DEFAULT_ADMIN_ROLE): `0xF8e03bd4436371E0e2F7C02E529b2172fe72b4EF`
- All five registrars granted REGISTRAR_ROLE
- Deployment mode: UUPS Proxy (upgradeable)
- Initial deployment (4 registrars): `broadcast/Deploy.s.sol/11155111/run-latest.json`
- SignedRegistrar addition: `broadcast/DeploySignedRegistrar.s.sol/11155111/run-latest.json`
