// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import "../../src/PrimaryAgentRegistry.sol";
import "../../src/registrars/SignedRegistrar.sol";

contract SignedRegistrarTest is Test {
    PrimaryAgentRegistry public registry;
    SignedRegistrar public signedRegistrar;

    address admin = address(0xAD);
    address agentRegistry = address(0xA1);
    address agentRegistry2 = address(0xA2);

    uint256 signerPrivateKey = 0xBEEF;
    address signer;

    function setUp() public {
        signer = vm.addr(signerPrivateKey);

        PrimaryAgentRegistry impl = new PrimaryAgentRegistry(address(0));
        ERC1967Proxy proxy = new ERC1967Proxy(
            address(impl),
            abi.encodeCall(PrimaryAgentRegistry.initialize, (admin))
        );
        registry = PrimaryAgentRegistry(address(proxy));

        signedRegistrar = new SignedRegistrar(address(registry));

        bytes32 registrarRole = registry.REGISTRAR_ROLE();
        vm.prank(admin);
        registry.grantRole(registrarRole, address(signedRegistrar));
    }

    function _signRegistration(
        uint256 privateKey,
        address account,
        address agentReg,
        uint256 tokenId,
        uint256 deadline,
        uint256 nonce
    ) internal view returns (bytes memory) {
        bytes32 hash = keccak256(
            abi.encodePacked(account, agentReg, tokenId, deadline, block.chainid, address(signedRegistrar), nonce)
        );
        bytes32 ethHash = MessageHashUtils.toEthSignedMessageHash(hash);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, ethHash);
        return abi.encodePacked(r, s, v);
    }

    function test_RegisterWithValidSignature() public {
        uint256 tokenId = 42;
        uint256 nonce = signedRegistrar.nonces(signer);
        bytes memory sig = _signRegistration(signerPrivateKey, signer, agentRegistry, tokenId, 0, nonce);

        signedRegistrar.register(signer, agentRegistry, tokenId, 0, sig);

        (address resolvedRegistry, uint256 resolvedId) = registry.resolveAgentId(signer);
        assertEq(resolvedRegistry, agentRegistry);
        assertEq(resolvedId, tokenId);
        assertEq(signedRegistrar.nonces(signer), 1);
    }

    function test_RevertInvalidSignature() public {
        uint256 wrongKey = 0xDEAD;
        address wrongSigner = vm.addr(wrongKey);

        uint256 tokenId = 42;
        // Sign with wrongKey but try to register for `signer`
        bytes memory sig = _signRegistration(wrongKey, signer, agentRegistry, tokenId, 0, 0);

        vm.expectRevert("SignedRegistrar: invalid signature");
        signedRegistrar.register(signer, agentRegistry, tokenId, 0, sig);

        // Also verify wrongSigner != signer
        assertTrue(wrongSigner != signer);
    }

    function test_ClearWithValidSignature() public {
        uint256 tokenId = 42;
        // Register (nonce 0)
        bytes memory regSig = _signRegistration(signerPrivateKey, signer, agentRegistry, tokenId, 0, 0);
        signedRegistrar.register(signer, agentRegistry, tokenId, 0, regSig);

        // Clear registration (nonce 1) by registering with address(0)
        bytes memory clearSig = _signRegistration(signerPrivateKey, signer, address(0), 0, 0, 1);
        signedRegistrar.register(signer, address(0), 0, 0, clearSig);

        assertFalse(registry.isRegistered(signer));
        assertEq(signedRegistrar.nonces(signer), 2);
    }

    function test_RevertReplayRegister() public {
        uint256 tokenId = 42;
        // Register with nonce 0
        bytes memory sig = _signRegistration(signerPrivateKey, signer, agentRegistry, tokenId, 0, 0);
        signedRegistrar.register(signer, agentRegistry, tokenId, 0, sig);

        // Try to replay the same signature (nonce is now 1, recovery will produce wrong address)
        vm.expectRevert("SignedRegistrar: invalid signature");
        signedRegistrar.register(signer, agentRegistry, tokenId, 0, sig);
    }

    function test_ReRegisterWithNewNonce() public {
        // Register with nonce 0
        bytes memory sig0 = _signRegistration(signerPrivateKey, signer, agentRegistry, 42, 0, 0);
        signedRegistrar.register(signer, agentRegistry, 42, 0, sig0);

        // Re-register with different values using nonce 1
        bytes memory sig1 = _signRegistration(signerPrivateKey, signer, agentRegistry2, 99, 0, 1);
        signedRegistrar.register(signer, agentRegistry2, 99, 0, sig1);

        (address resolvedRegistry, uint256 resolvedId) = registry.resolveAgentId(signer);
        assertEq(resolvedRegistry, agentRegistry2);
        assertEq(resolvedId, 99);
    }

    function test_RevertExpiredDeadline() public {
        // Warp to a realistic timestamp so deadline can be in the past
        vm.warp(1_700_000_000);
        uint256 tokenId = 42;
        uint256 deadline = block.timestamp - 1; // already expired
        bytes memory sig = _signRegistration(signerPrivateKey, signer, agentRegistry, tokenId, deadline, 0);

        vm.expectRevert("SignedRegistrar: expired");
        signedRegistrar.register(signer, agentRegistry, tokenId, deadline, sig);
    }

    function test_RegisterWithDeadline() public {
        uint256 tokenId = 42;
        uint256 deadline = block.timestamp + 1 hours;
        bytes memory sig = _signRegistration(signerPrivateKey, signer, agentRegistry, tokenId, deadline, 0);

        signedRegistrar.register(signer, agentRegistry, tokenId, deadline, sig);

        (address resolvedRegistry, uint256 resolvedId) = registry.resolveAgentId(signer);
        assertEq(resolvedRegistry, agentRegistry);
        assertEq(resolvedId, tokenId);
    }

    function test_RevertZeroAddressRegistry() public {
        vm.expectRevert("SignedRegistrar: zero registry");
        new SignedRegistrar(address(0));
    }

    function test_EmitsSignedRegistration() public {
        uint256 tokenId = 42;
        bytes memory sig = _signRegistration(signerPrivateKey, signer, agentRegistry, tokenId, 0, 0);

        vm.expectEmit(true, true, false, true);
        emit SignedRegistrar.SignedRegistration(signer, agentRegistry, tokenId, 0);
        signedRegistrar.register(signer, agentRegistry, tokenId, 0, sig);
    }
}
