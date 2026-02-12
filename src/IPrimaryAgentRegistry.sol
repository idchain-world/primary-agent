// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

/// @title IPrimaryAgentRegistry - Reverse resolution from Ethereum addresses to agent token IDs
/// @notice A singleton registry mapping Ethereum addresses to their agent identity.
///         Each address maps to a packed bytes value: [20B registry][1B id-length][NB token-id].
///         For token IDs up to 10 bytes (2^80), the entire value fits in a single storage slot.
///         To clear a registration, call register with registry = address(0).
interface IPrimaryAgentRegistry {
    /// @notice Emitted when an agent registration is set, updated, or cleared
    /// @dev When registry is address(0), the registration has been cleared
    event AgentRegistered(address indexed account, address indexed registry, uint256 tokenId);

    /// @notice Register or clear an account's agent identity
    /// @dev Only callable by addresses with REGISTRAR_ROLE.
    ///      Pass registry = address(0) to clear a registration.
    /// @param account The Ethereum address to register
    /// @param registry The agent registry contract address (address(0) to clear)
    /// @param tokenId The token ID within the registry (ignored when clearing)
    function register(address account, address registry, uint256 tokenId) external;

    /// @notice Reverse-resolve an Ethereum address to its agent identity
    /// @param account The Ethereum address to resolve
    /// @return registry The agent registry address (address(0) if none)
    /// @return tokenId The token ID in the registry (0 if none)
    function resolveAgentId(address account) external view returns (address registry, uint256 tokenId);

    /// @notice Get the raw packed agent data for an account
    /// @param account The Ethereum address
    /// @return The packed bytes: [20B registry][1B id-length][NB token-id], or empty if unregistered
    function agentData(address account) external view returns (bytes memory);

    /// @notice Check if an account is registered
    /// @param account The Ethereum address
    /// @return Whether the account has a registration
    function isRegistered(address account) external view returns (bool);
}
