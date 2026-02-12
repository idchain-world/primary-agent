// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "../src/PrimaryAgentRegistry.sol";
import "../src/registrars/SelfRegistrar.sol";

contract PrimaryAgentRegistryTest is Test {
    PrimaryAgentRegistry public registry;
    SelfRegistrar public selfRegistrar;

    address admin = address(0xAD);
    address user1 = address(0x1);
    address user2 = address(0x2);
    address agentRegistry1 = address(0xA1);
    address agentRegistry2 = address(0xA2);

    function setUp() public {
        // Deploy implementation (address(0) = proxy mode) + proxy
        PrimaryAgentRegistry impl = new PrimaryAgentRegistry(address(0));
        ERC1967Proxy proxy = new ERC1967Proxy(
            address(impl),
            abi.encodeCall(PrimaryAgentRegistry.initialize, (admin))
        );
        registry = PrimaryAgentRegistry(address(proxy));

        selfRegistrar = new SelfRegistrar(address(registry));

        bytes32 registrarRole = registry.REGISTRAR_ROLE();
        vm.prank(admin);
        registry.grantRole(registrarRole, address(selfRegistrar));
    }

    function test_SelfRegister() public {
        vm.prank(user1);
        selfRegistrar.register(agentRegistry1, 42);

        (address resolvedRegistry, uint256 resolvedId) = registry.resolveAgentId(user1);
        assertEq(resolvedRegistry, agentRegistry1);
        assertEq(resolvedId, 42);
    }

    function test_ResolveUnregistered() public view {
        (address resolvedRegistry, uint256 resolvedId) = registry.resolveAgentId(user1);
        assertEq(resolvedRegistry, address(0));
        assertEq(resolvedId, 0);
    }

    function test_Overwrite() public {
        vm.startPrank(user1);
        selfRegistrar.register(agentRegistry1, 10);
        selfRegistrar.register(agentRegistry2, 99);
        vm.stopPrank();

        (address resolvedRegistry, uint256 resolvedId) = registry.resolveAgentId(user1);
        assertEq(resolvedRegistry, agentRegistry2);
        assertEq(resolvedId, 99);
    }

    function test_ClearRegistration() public {
        vm.startPrank(user1);
        selfRegistrar.register(agentRegistry1, 42);
        selfRegistrar.register(address(0), 0);
        vm.stopPrank();

        (address resolvedRegistry, uint256 resolvedId) = registry.resolveAgentId(user1);
        assertEq(resolvedRegistry, address(0));
        assertEq(resolvedId, 0);
        assertFalse(registry.isRegistered(user1));
    }

    function test_RegisterTokenIdZero() public {
        vm.prank(user1);
        selfRegistrar.register(agentRegistry1, 0);

        (address resolvedRegistry, uint256 resolvedId) = registry.resolveAgentId(user1);
        assertEq(resolvedRegistry, agentRegistry1);
        assertEq(resolvedId, 0);
        assertTrue(registry.isRegistered(user1));
    }

    function test_LargeTokenId() public {
        uint256 largeId = type(uint256).max;
        vm.prank(user1);
        selfRegistrar.register(agentRegistry1, largeId);

        (address resolvedRegistry, uint256 resolvedId) = registry.resolveAgentId(user1);
        assertEq(resolvedRegistry, agentRegistry1);
        assertEq(resolvedId, largeId);
    }

    function test_TokenId256() public {
        vm.prank(user1);
        selfRegistrar.register(agentRegistry1, 256);

        (address resolvedRegistry, uint256 resolvedId) = registry.resolveAgentId(user1);
        assertEq(resolvedRegistry, agentRegistry1);
        assertEq(resolvedId, 256);
    }

    function test_IsRegistered() public {
        assertFalse(registry.isRegistered(user1));

        vm.prank(user1);
        selfRegistrar.register(agentRegistry1, 42);

        assertTrue(registry.isRegistered(user1));
    }

    function test_AgentData() public {
        vm.prank(user1);
        selfRegistrar.register(agentRegistry1, 42);

        bytes memory data = registry.agentData(user1);
        assertEq(data.length, 22);
    }

    function test_AgentDataTokenIdZero() public {
        vm.prank(user1);
        selfRegistrar.register(agentRegistry1, 0);

        bytes memory data = registry.agentData(user1);
        assertEq(data.length, 21);
    }

    function test_RevertUnauthorizedRegister() public {
        vm.prank(user1);
        vm.expectRevert();
        registry.register(user1, agentRegistry1, 42);
    }

    function test_RevertZeroAddressAccount() public {
        bytes32 registrarRole = registry.REGISTRAR_ROLE();
        vm.prank(admin);
        registry.grantRole(registrarRole, admin);

        vm.prank(admin);
        vm.expectRevert("PrimaryAgentRegistry: zero address account");
        registry.register(address(0), agentRegistry1, 42);
    }

    function test_ClearRegistrationViaZeroRegistry() public {
        bytes32 registrarRole = registry.REGISTRAR_ROLE();
        vm.prank(admin);
        registry.grantRole(registrarRole, admin);

        vm.prank(admin);
        registry.register(user1, agentRegistry1, 42);

        vm.prank(admin);
        registry.register(user1, address(0), 0);

        assertFalse(registry.isRegistered(user1));
    }

    event AgentRegistered(address indexed account, address indexed registry, uint256 tokenId);

    function test_RegisterEvent() public {
        vm.prank(user1);

        vm.expectEmit(true, true, false, true);
        emit AgentRegistered(user1, agentRegistry1, 42);

        selfRegistrar.register(agentRegistry1, 42);
    }

    function test_ClearEvent() public {
        vm.prank(user1);
        selfRegistrar.register(agentRegistry1, 42);

        vm.prank(user1);

        vm.expectEmit(true, true, false, true);
        emit AgentRegistered(user1, address(0), 0);

        selfRegistrar.register(address(0), 0);
    }

    function test_SingleSlotForSmallId() public {
        vm.prank(user1);
        selfRegistrar.register(agentRegistry1, 42);

        bytes memory data = registry.agentData(user1);
        assertTrue(data.length <= 31, "Should fit in single storage slot");
    }

    function test_SingleSlotForTenByteId() public {
        uint256 tenByteId = (uint256(1) << 79) - 1;
        vm.prank(user1);
        selfRegistrar.register(agentRegistry1, tenByteId);

        bytes memory data = registry.agentData(user1);
        assertEq(data.length, 31, "10-byte ID should produce 31 bytes total");

        (address resolvedRegistry, uint256 resolvedId) = registry.resolveAgentId(user1);
        assertEq(resolvedRegistry, agentRegistry1);
        assertEq(resolvedId, tenByteId);
    }

    // --- UUPS upgrade tests ---

    function test_UpgradeByAdmin() public {
        PrimaryAgentRegistry newImpl = new PrimaryAgentRegistry(address(0));

        vm.prank(admin);
        registry.upgradeToAndCall(address(newImpl), "");
    }

    function test_RevertUpgradeByNonAdmin() public {
        PrimaryAgentRegistry newImpl = new PrimaryAgentRegistry(address(0));

        vm.prank(user1);
        vm.expectRevert();
        registry.upgradeToAndCall(address(newImpl), "");
    }

    function test_StatePreservedAfterUpgrade() public {
        vm.prank(user1);
        selfRegistrar.register(agentRegistry1, 42);

        PrimaryAgentRegistry newImpl = new PrimaryAgentRegistry(address(0));
        vm.prank(admin);
        registry.upgradeToAndCall(address(newImpl), "");

        (address resolvedRegistry, uint256 resolvedId) = registry.resolveAgentId(user1);
        assertEq(resolvedRegistry, agentRegistry1);
        assertEq(resolvedId, 42);
    }

    function test_RevertInitializeImplementation() public {
        PrimaryAgentRegistry impl = new PrimaryAgentRegistry(address(0));

        vm.expectRevert();
        impl.initialize(admin);
    }

    function test_RevertDoubleInitialize() public {
        vm.expectRevert();
        registry.initialize(user1);
    }

    // --- Standalone (non-proxy) deployment tests ---

    function test_StandaloneDeployment() public {
        PrimaryAgentRegistry standalone = new PrimaryAgentRegistry(admin);

        assertTrue(standalone.hasRole(standalone.DEFAULT_ADMIN_ROLE(), admin));
    }

    function test_StandaloneRegisterAndResolve() public {
        PrimaryAgentRegistry standalone = new PrimaryAgentRegistry(admin);

        SelfRegistrar sr = new SelfRegistrar(address(standalone));
        bytes32 registrarRole = standalone.REGISTRAR_ROLE();
        vm.prank(admin);
        standalone.grantRole(registrarRole, address(sr));

        vm.prank(user1);
        sr.register(agentRegistry1, 42);

        (address resolvedRegistry, uint256 resolvedId) = standalone.resolveAgentId(user1);
        assertEq(resolvedRegistry, agentRegistry1);
        assertEq(resolvedId, 42);
    }

    function test_StandaloneRevertDoubleInitialize() public {
        PrimaryAgentRegistry standalone = new PrimaryAgentRegistry(admin);

        vm.expectRevert();
        standalone.initialize(user1);
    }
}
