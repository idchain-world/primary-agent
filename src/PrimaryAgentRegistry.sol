// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "./IPrimaryAgentRegistry.sol";

/// @title PrimaryAgentRegistry - Singleton registry for reverse resolution of Ethereum addresses to agents
/// @notice Maps each Ethereum address to a single packed bytes value encoding the agent registry
///         address and token ID. The encoding is: [20B registry][1B id-length][NB token-id].
///         For token IDs up to 10 bytes (2^80), the packed value is <=31 bytes and Solidity
///         stores it in a single storage slot. Designed as a UUPS-upgradeable singleton
///         deployed to every chain. Supports both UUPS proxy and standalone deployment.
contract PrimaryAgentRegistry is IPrimaryAgentRegistry, AccessControlUpgradeable, UUPSUpgradeable {
    bytes32 public constant REGISTRAR_ROLE = keccak256("REGISTRAR_ROLE");

    /// @dev account => packed bytes [20B registry][1B id-length][NB token-id]
    mapping(address => bytes) private _agents;

    /// @notice Deploy as standalone (admin != address(0)) or as proxy implementation (admin == address(0))
    /// @param admin Pass a non-zero address for standalone deployment, or address(0) for proxy implementation
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address admin) {
        if (admin == address(0)) {
            _disableInitializers();
        } else {
            initialize(admin);
        }
    }

    /// @notice Initialize the registry (called once via proxy, or internally by constructor for standalone)
    /// @param admin The address to receive DEFAULT_ADMIN_ROLE
    function initialize(address admin) public initializer {
        __AccessControl_init();
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
    }

    /// @inheritdoc IPrimaryAgentRegistry
    function register(address account, address registry, uint256 tokenId) external onlyRole(REGISTRAR_ROLE) {
        require(account != address(0), "PrimaryAgentRegistry: zero address account");

        if (registry == address(0)) {
            delete _agents[account];
        } else {
            _agents[account] = _encode(registry, tokenId);
        }

        emit AgentRegistered(account, registry, tokenId);
    }

    /// @inheritdoc IPrimaryAgentRegistry
    function resolveAgentId(address account) external view returns (address registry, uint256 tokenId) {
        bytes storage data = _agents[account];
        if (data.length == 0) return (address(0), 0);
        return _decode(data);
    }

    /// @inheritdoc IPrimaryAgentRegistry
    function agentData(address account) external view returns (bytes memory) {
        return _agents[account];
    }

    /// @inheritdoc IPrimaryAgentRegistry
    function isRegistered(address account) external view returns (bool) {
        return _agents[account].length > 0;
    }

    /// @dev Only DEFAULT_ADMIN_ROLE can authorize upgrades
    function _authorizeUpgrade(address) internal override onlyRole(DEFAULT_ADMIN_ROLE) {}

    /// @dev Reserved storage gap for future upgrades
    uint256[49] private __gap;

    /// @dev Pack registry address and token ID into minimal bytes
    ///      Format: [20B registry][1B id-length][NB token-id (big-endian)]
    function _encode(address registry, uint256 tokenId) internal pure returns (bytes memory) {
        uint8 idLen = _byteLength(tokenId);
        bytes memory data = new bytes(21 + idLen);

        // Pack registry address (20 bytes)
        assembly {
            mstore(add(data, 32), shl(96, registry))
        }

        // Pack id byte length
        data[20] = bytes1(idLen);

        // Pack token ID in big-endian minimal bytes
        for (uint8 i = 0; i < idLen; i++) {
            data[20 + idLen - i] = bytes1(uint8(tokenId >> (i * 8)));
        }

        return data;
    }

    /// @dev Unpack registry address and token ID from packed bytes
    function _decode(bytes storage data) internal view returns (address registry, uint256 tokenId) {
        bytes memory d = data;

        assembly {
            registry := shr(96, mload(add(d, 32)))
        }

        uint8 idLen = uint8(d[20]);

        for (uint8 i = 0; i < idLen; i++) {
            tokenId = (tokenId << 8) | uint256(uint8(d[21 + i]));
        }
    }

    /// @dev Return the minimal number of bytes needed to represent a uint256
    function _byteLength(uint256 value) internal pure returns (uint8) {
        if (value == 0) return 0;
        uint8 len = 0;
        while (value > 0) {
            len++;
            value >>= 8;
        }
        return len;
    }
}
