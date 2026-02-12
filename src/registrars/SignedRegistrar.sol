// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import "../PrimaryAgentRegistry.sol";

/// @title SignedRegistrar - Register EOAs via ECDSA signature verification
/// @notice Allows an EOA to sign a message off-chain, and then anyone can submit
///         that signature on-chain to register on the EOA's behalf. Useful for
///         meta-transactions, gasless registration, and delegation.
///         Includes per-account nonce to prevent signature replay attacks.
///         To clear a registration, pass registry = address(0).
contract SignedRegistrar {
    PrimaryAgentRegistry public immutable primaryAgentRegistry;

    /// @dev Per-account nonce to prevent signature replay
    mapping(address => uint256) public nonces;

    event SignedRegistration(address indexed account, address indexed registry, uint256 tokenId, uint256 nonce);

    constructor(address _primaryAgentRegistry) {
        require(_primaryAgentRegistry != address(0), "SignedRegistrar: zero registry");
        primaryAgentRegistry = PrimaryAgentRegistry(_primaryAgentRegistry);
    }

    /// @notice Register or clear an EOA's agent identity via ECDSA signature
    /// @param account The EOA address to register
    /// @param registry The agent registry contract address (address(0) to clear)
    /// @param tokenId The token ID within the registry
    /// @param deadline Timestamp after which the signature expires (0 for no expiry)
    /// @param signature The ECDSA signature over the registration hash
    function register(
        address account,
        address registry,
        uint256 tokenId,
        uint256 deadline,
        bytes calldata signature
    ) external {
        require(deadline == 0 || block.timestamp <= deadline, "SignedRegistrar: expired");

        // Nonce is incremented atomically; reverts on invalid signature roll back the increment
        uint256 nonce = nonces[account]++;

        bytes32 hash = keccak256(
            abi.encodePacked(account, registry, tokenId, deadline, block.chainid, address(this), nonce)
        );
        bytes32 ethHash = MessageHashUtils.toEthSignedMessageHash(hash);
        address signer = ECDSA.recover(ethHash, signature);
        require(signer == account, "SignedRegistrar: invalid signature");

        primaryAgentRegistry.register(account, registry, tokenId);

        emit SignedRegistration(account, registry, tokenId, nonce);
    }
}
