// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "../../src/PrimaryAgentRegistry.sol";
import "../../src/registrars/AccessControlRegistrar.sol";

contract MockAccessControlled is AccessControl {
    constructor(address admin) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
    }
}

contract AccessControlRegistrarTest is Test {
    PrimaryAgentRegistry public registry;
    AccessControlRegistrar public acRegistrar;

    address admin = address(0xAD);
    address contractAdmin = address(0x1);
    address nonAdmin = address(0x2);
    address agentRegistry = address(0xA1);

    function setUp() public {
        PrimaryAgentRegistry impl = new PrimaryAgentRegistry(address(0));
        ERC1967Proxy proxy = new ERC1967Proxy(
            address(impl),
            abi.encodeCall(PrimaryAgentRegistry.initialize, (admin))
        );
        registry = PrimaryAgentRegistry(address(proxy));

        acRegistrar = new AccessControlRegistrar(address(registry));

        bytes32 registrarRole = registry.REGISTRAR_ROLE();
        vm.prank(admin);
        registry.grantRole(registrarRole, address(acRegistrar));
    }

    function test_RegisterViaAdmin() public {
        MockAccessControlled controlled = new MockAccessControlled(contractAdmin);

        vm.prank(contractAdmin);
        acRegistrar.register(address(controlled), agentRegistry, 42);

        (address resolvedRegistry, uint256 resolvedId) = registry.resolveAgentId(address(controlled));
        assertEq(resolvedRegistry, agentRegistry);
        assertEq(resolvedId, 42);
    }

    function test_RevertNonAdmin() public {
        MockAccessControlled controlled = new MockAccessControlled(contractAdmin);

        vm.prank(nonAdmin);
        vm.expectRevert("AccessControlRegistrar: caller is not admin");
        acRegistrar.register(address(controlled), agentRegistry, 42);
    }

    function test_ClearViaAdmin() public {
        MockAccessControlled controlled = new MockAccessControlled(contractAdmin);

        vm.prank(contractAdmin);
        acRegistrar.register(address(controlled), agentRegistry, 42);

        vm.prank(contractAdmin);
        acRegistrar.register(address(controlled), address(0), 0);

        assertFalse(registry.isRegistered(address(controlled)));
    }
}
