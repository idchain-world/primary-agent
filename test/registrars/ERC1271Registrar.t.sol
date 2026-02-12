// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "../../src/PrimaryAgentRegistry.sol";
import "../../src/registrars/ERC1271Registrar.sol";

contract MockERC1271Wallet {
    bytes4 private constant ERC1271_MAGIC_VALUE = 0x1626ba7e;
    bytes32 public expectedHash;

    function setExpectedHash(bytes32 hash) external {
        expectedHash = hash;
    }

    function isValidSignature(bytes32 hash, bytes calldata) external view returns (bytes4) {
        if (hash == expectedHash) {
            return ERC1271_MAGIC_VALUE;
        }
        return 0xffffffff;
    }
}

contract MockBadWallet {
    function isValidSignature(bytes32, bytes calldata) external pure returns (bytes4) {
        return 0xffffffff;
    }
}

contract ERC1271RegistrarTest is Test {
    PrimaryAgentRegistry public registry;
    ERC1271Registrar public erc1271Registrar;

    address admin = address(0xAD);
    address agentRegistry = address(0xA1);
    address agentRegistry2 = address(0xA2);

    function setUp() public {
        PrimaryAgentRegistry impl = new PrimaryAgentRegistry(address(0));
        ERC1967Proxy proxy = new ERC1967Proxy(
            address(impl),
            abi.encodeCall(PrimaryAgentRegistry.initialize, (admin))
        );
        registry = PrimaryAgentRegistry(address(proxy));

        erc1271Registrar = new ERC1271Registrar(address(registry));

        bytes32 registrarRole = registry.REGISTRAR_ROLE();
        vm.prank(admin);
        registry.grantRole(registrarRole, address(erc1271Registrar));
    }

    function test_RegisterWithValidSignature() public {
        MockERC1271Wallet wallet = new MockERC1271Wallet();

        uint256 tokenId = 42;
        uint256 nonce = erc1271Registrar.nonces(address(wallet));
        bytes32 hash = keccak256(
            abi.encodePacked(address(wallet), agentRegistry, tokenId, block.chainid, address(erc1271Registrar), nonce)
        );
        wallet.setExpectedHash(hash);

        erc1271Registrar.register(address(wallet), agentRegistry, tokenId, "");

        (address resolvedRegistry, uint256 resolvedId) = registry.resolveAgentId(address(wallet));
        assertEq(resolvedRegistry, agentRegistry);
        assertEq(resolvedId, tokenId);
        assertEq(erc1271Registrar.nonces(address(wallet)), 1);
    }

    function test_RevertInvalidSignature() public {
        MockBadWallet wallet = new MockBadWallet();

        vm.expectRevert("ERC1271Registrar: invalid signature");
        erc1271Registrar.register(address(wallet), agentRegistry, 42, "");
    }

    function test_ClearWithValidSignature() public {
        MockERC1271Wallet wallet = new MockERC1271Wallet();

        uint256 tokenId = 42;
        // Register (nonce 0)
        bytes32 regHash = keccak256(
            abi.encodePacked(address(wallet), agentRegistry, tokenId, block.chainid, address(erc1271Registrar), uint256(0))
        );
        wallet.setExpectedHash(regHash);
        erc1271Registrar.register(address(wallet), agentRegistry, tokenId, "");

        // Clear registration (nonce 1) by registering with address(0)
        bytes32 clearHash = keccak256(
            abi.encodePacked(address(wallet), address(0), uint256(0), block.chainid, address(erc1271Registrar), uint256(1))
        );
        wallet.setExpectedHash(clearHash);
        erc1271Registrar.register(address(wallet), address(0), 0, "");

        assertFalse(registry.isRegistered(address(wallet)));
        assertEq(erc1271Registrar.nonces(address(wallet)), 2);
    }

    function test_RevertReplayRegister() public {
        MockERC1271Wallet wallet = new MockERC1271Wallet();

        uint256 tokenId = 42;
        // Register with nonce 0
        bytes32 hash0 = keccak256(
            abi.encodePacked(address(wallet), agentRegistry, tokenId, block.chainid, address(erc1271Registrar), uint256(0))
        );
        wallet.setExpectedHash(hash0);
        erc1271Registrar.register(address(wallet), agentRegistry, tokenId, "");

        // Try to replay the same signature (nonce is now 1, hash won't match)
        vm.expectRevert("ERC1271Registrar: invalid signature");
        erc1271Registrar.register(address(wallet), agentRegistry, tokenId, "");
    }

    function test_ReRegisterWithNewNonce() public {
        MockERC1271Wallet wallet = new MockERC1271Wallet();

        // Register with nonce 0
        bytes32 hash0 = keccak256(
            abi.encodePacked(address(wallet), agentRegistry, uint256(42), block.chainid, address(erc1271Registrar), uint256(0))
        );
        wallet.setExpectedHash(hash0);
        erc1271Registrar.register(address(wallet), agentRegistry, 42, "");

        // Re-register with different values using nonce 1
        bytes32 hash1 = keccak256(
            abi.encodePacked(address(wallet), agentRegistry2, uint256(99), block.chainid, address(erc1271Registrar), uint256(1))
        );
        wallet.setExpectedHash(hash1);
        erc1271Registrar.register(address(wallet), agentRegistry2, 99, "");

        (address resolvedRegistry, uint256 resolvedId) = registry.resolveAgentId(address(wallet));
        assertEq(resolvedRegistry, agentRegistry2);
        assertEq(resolvedId, 99);
    }
}
