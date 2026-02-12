// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "../PrimaryAgentRegistry.sol";

/// @title SelfRegistrar - Allows any EOA to register itself
/// @notice The simplest registrar: msg.sender registers their own agent identity.
contract SelfRegistrar {
    PrimaryAgentRegistry public immutable primaryAgent;

    constructor(address _primaryAgent) {
        primaryAgent = PrimaryAgentRegistry(_primaryAgent);
    }

    /// @notice Register or clear msg.sender's agent identity
    /// @param registry The agent registry contract address (address(0) to clear)
    /// @param tokenId The token ID within the registry
    function register(address registry, uint256 tokenId) external {
        primaryAgent.register(msg.sender, registry, tokenId);
    }
}
