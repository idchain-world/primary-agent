// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "forge-std/Script.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "../src/PrimaryAgentRegistry.sol";
import "../src/registrars/SelfRegistrar.sol";
import "../src/registrars/ERC1271Registrar.sol";
import "../src/registrars/OwnableRegistrar.sol";
import "../src/registrars/AccessControlRegistrar.sol";
import "../src/registrars/SignedRegistrar.sol";

contract Deploy is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("Deployer:", deployer);
        console.log("Chain ID:", block.chainid);

        vm.startBroadcast(deployerPrivateKey);

        // 1. Deploy implementation (proxy mode)
        PrimaryAgentRegistry impl = new PrimaryAgentRegistry(address(0));
        console.log("Implementation:", address(impl));

        // 2. Deploy proxy with initialization
        ERC1967Proxy proxy = new ERC1967Proxy(
            address(impl),
            abi.encodeCall(PrimaryAgentRegistry.initialize, (deployer))
        );
        PrimaryAgentRegistry registry = PrimaryAgentRegistry(address(proxy));
        console.log("Proxy (Registry):", address(proxy));

        // 3. Deploy registrars
        SelfRegistrar selfRegistrar = new SelfRegistrar(address(registry));
        console.log("SelfRegistrar:", address(selfRegistrar));

        ERC1271Registrar erc1271Registrar = new ERC1271Registrar(address(registry));
        console.log("ERC1271Registrar:", address(erc1271Registrar));

        OwnableRegistrar ownableRegistrar = new OwnableRegistrar(address(registry));
        console.log("OwnableRegistrar:", address(ownableRegistrar));

        AccessControlRegistrar acRegistrar = new AccessControlRegistrar(address(registry));
        console.log("AccessControlRegistrar:", address(acRegistrar));

        SignedRegistrar signedRegistrar = new SignedRegistrar(address(registry));
        console.log("SignedRegistrar:", address(signedRegistrar));

        // 4. Grant REGISTRAR_ROLE to each registrar
        bytes32 registrarRole = registry.REGISTRAR_ROLE();
        registry.grantRole(registrarRole, address(selfRegistrar));
        registry.grantRole(registrarRole, address(erc1271Registrar));
        registry.grantRole(registrarRole, address(ownableRegistrar));
        registry.grantRole(registrarRole, address(acRegistrar));
        registry.grantRole(registrarRole, address(signedRegistrar));

        console.log("REGISTRAR_ROLE granted to all registrars");

        vm.stopBroadcast();
    }
}
