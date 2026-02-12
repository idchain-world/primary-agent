// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "../PrimaryAgentRegistry.sol";

/// @title ERC1271Registrar - Register smart contract wallets via ERC-1271 signature verification
/// @notice Allows smart contracts that implement ERC-1271 (isValidSignature) to register
///         their agent identity by providing a valid signature over the registration data.
///         Includes per-account nonce to prevent signature replay attacks.
///         To clear a registration, pass registry = address(0).
contract ERC1271Registrar {
    PrimaryAgentRegistry public immutable primaryAgentRegistry;

    /// @dev Per-account nonce to prevent signature replay
    mapping(address => uint256) public nonces;

    // ERC-1271 magic value returned on successful validation
    bytes4 private constant ERC1271_MAGIC_VALUE = 0x1626ba7e;

    constructor(address _primaryAgentRegistry) {
        primaryAgentRegistry = PrimaryAgentRegistry(_primaryAgentRegistry);
    }

    /// @notice Register or clear a smart contract's agent identity via ERC-1271 signature
    /// @param account The smart contract address to register
    /// @param registry The agent registry contract address (address(0) to clear)
    /// @param tokenId The token ID within the registry
    /// @param signature The ERC-1271 signature over the registration hash
    function register(address account, address registry, uint256 tokenId, bytes calldata signature) external {
        uint256 nonce = nonces[account]++;

        bytes32 hash = keccak256(
            abi.encodePacked(account, registry, tokenId, block.chainid, address(this), nonce)
        );

        (bool success, bytes memory result) =
            account.staticcall(abi.encodeWithSignature("isValidSignature(bytes32,bytes)", hash, signature));

        require(
            success && result.length >= 32 && abi.decode(result, (bytes4)) == ERC1271_MAGIC_VALUE,
            "ERC1271Registrar: invalid signature"
        );

        primaryAgentRegistry.register(account, registry, tokenId);
    }
}
