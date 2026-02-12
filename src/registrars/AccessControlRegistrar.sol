// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "../PrimaryAgentRegistry.sol";

/// @title AccessControlRegistrar - Register contracts via AccessControl DEFAULT_ADMIN_ROLE
/// @notice Allows the DEFAULT_ADMIN_ROLE holder of a contract that implements AccessControl
///         to register the contract's agent identity.
contract AccessControlRegistrar {
    PrimaryAgentRegistry public immutable primaryAgent;

    bytes32 private constant DEFAULT_ADMIN_ROLE = 0x00;

    constructor(address _primaryAgent) {
        primaryAgent = PrimaryAgentRegistry(_primaryAgent);
    }

    /// @notice Register or clear a contract's agent identity (caller must have DEFAULT_ADMIN_ROLE)
    /// @param contractAddress The contract to register (must implement AccessControl)
    /// @param registry The agent registry contract address (address(0) to clear)
    /// @param tokenId The token ID within the registry
    function register(address contractAddress, address registry, uint256 tokenId) external {
        require(_isAdmin(contractAddress, msg.sender), "AccessControlRegistrar: caller is not admin");
        primaryAgent.register(contractAddress, registry, tokenId);
    }

    /// @dev Check if caller has DEFAULT_ADMIN_ROLE on the target contract
    function _isAdmin(address contractAddress, address caller) internal view returns (bool) {
        (bool success, bytes memory result) = contractAddress.staticcall(
            abi.encodeWithSignature("hasRole(bytes32,address)", DEFAULT_ADMIN_ROLE, caller)
        );
        return success && result.length >= 32 && abi.decode(result, (bool));
    }
}
