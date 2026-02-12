// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "../../src/PrimaryAgentRegistry.sol";
import "../../src/registrars/OwnableRegistrar.sol";

contract MockOwnable {
    address public owner;

    constructor(address _owner) {
        owner = _owner;
    }
}

contract MockGetOwner {
    address private _owner;

    constructor(address owner_) {
        _owner = owner_;
    }

    function getOwner() external view returns (address) {
        return _owner;
    }
}

contract OwnableRegistrarTest is Test {
    PrimaryAgentRegistry public registry;
    OwnableRegistrar public ownableRegistrar;

    address admin = address(0xAD);
    address contractOwner = address(0x1);
    address nonOwner = address(0x2);
    address agentRegistry = address(0xA1);

    function setUp() public {
        PrimaryAgentRegistry impl = new PrimaryAgentRegistry(address(0));
        ERC1967Proxy proxy = new ERC1967Proxy(
            address(impl),
            abi.encodeCall(PrimaryAgentRegistry.initialize, (admin))
        );
        registry = PrimaryAgentRegistry(address(proxy));

        ownableRegistrar = new OwnableRegistrar(address(registry));

        bytes32 registrarRole = registry.REGISTRAR_ROLE();
        vm.prank(admin);
        registry.grantRole(registrarRole, address(ownableRegistrar));
    }

    function test_RegisterViaOwner() public {
        MockOwnable ownableContract = new MockOwnable(contractOwner);

        vm.prank(contractOwner);
        ownableRegistrar.register(address(ownableContract), agentRegistry, 42);

        (address resolvedRegistry, uint256 resolvedId) = registry.resolveAgentId(address(ownableContract));
        assertEq(resolvedRegistry, agentRegistry);
        assertEq(resolvedId, 42);
    }

    function test_RegisterViaGetOwner() public {
        MockGetOwner getOwnerContract = new MockGetOwner(contractOwner);

        vm.prank(contractOwner);
        ownableRegistrar.register(address(getOwnerContract), agentRegistry, 42);

        (address resolvedRegistry, uint256 resolvedId) = registry.resolveAgentId(address(getOwnerContract));
        assertEq(resolvedRegistry, agentRegistry);
        assertEq(resolvedId, 42);
    }

    function test_RevertNonOwner() public {
        MockOwnable ownableContract = new MockOwnable(contractOwner);

        vm.prank(nonOwner);
        vm.expectRevert("OwnableRegistrar: caller is not owner");
        ownableRegistrar.register(address(ownableContract), agentRegistry, 42);
    }

    function test_ClearViaOwner() public {
        MockOwnable ownableContract = new MockOwnable(contractOwner);

        vm.prank(contractOwner);
        ownableRegistrar.register(address(ownableContract), agentRegistry, 42);

        vm.prank(contractOwner);
        ownableRegistrar.register(address(ownableContract), address(0), 0);

        assertFalse(registry.isRegistered(address(ownableContract)));
    }
}
