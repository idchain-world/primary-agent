// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "../PrimaryAgentRegistry.sol";

/// @title OwnableRegistrar - Register contracts via owner() or getOwner()
/// @notice Allows the owner of a contract (that implements owner() or getOwner()) to
///         register the contract's agent identity. Supports both OpenZeppelin Ownable
///         and contracts that use getOwner().
contract OwnableRegistrar {
    PrimaryAgentRegistry public immutable primaryAgent;

    constructor(address _primaryAgent) {
        primaryAgent = PrimaryAgentRegistry(_primaryAgent);
    }

    /// @notice Register or clear a contract's agent identity (caller must be the contract's owner)
    /// @param contractAddress The contract to register
    /// @param registry The agent registry contract address (address(0) to clear)
    /// @param tokenId The token ID within the registry
    function register(address contractAddress, address registry, uint256 tokenId) external {
        require(_isOwner(contractAddress, msg.sender), "OwnableRegistrar: caller is not owner");
        primaryAgent.register(contractAddress, registry, tokenId);
    }

    /// @dev Check if caller is the owner via owner() or getOwner()
    function _isOwner(address contractAddress, address caller) internal view returns (bool) {
        // Try owner() first (OpenZeppelin Ownable)
        (bool success, bytes memory result) =
            contractAddress.staticcall(abi.encodeWithSignature("owner()"));
        if (success && result.length >= 32) {
            address owner = abi.decode(result, (address));
            if (owner == caller) return true;
        }

        // Try getOwner() as fallback
        (success, result) = contractAddress.staticcall(abi.encodeWithSignature("getOwner()"));
        if (success && result.length >= 32) {
            address owner = abi.decode(result, (address));
            if (owner == caller) return true;
        }

        return false;
    }
}
