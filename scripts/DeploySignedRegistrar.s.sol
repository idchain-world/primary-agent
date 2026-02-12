// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "forge-std/Script.sol";
import "../src/PrimaryAgentRegistry.sol";
import "../src/registrars/SignedRegistrar.sol";

contract DeploySignedRegistrar is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        address registryProxy = vm.envAddress("REGISTRY_PROXY");

        console.log("Deployer:", deployer);
        console.log("Chain ID:", block.chainid);
        console.log("Registry Proxy:", registryProxy);

        PrimaryAgentRegistry registry = PrimaryAgentRegistry(registryProxy);

        vm.startBroadcast(deployerPrivateKey);

        // 1. Deploy SignedRegistrar
        SignedRegistrar signedRegistrar = new SignedRegistrar(registryProxy);
        console.log("SignedRegistrar:", address(signedRegistrar));

        // 2. Grant REGISTRAR_ROLE
        bytes32 registrarRole = registry.REGISTRAR_ROLE();
        registry.grantRole(registrarRole, address(signedRegistrar));
        console.log("REGISTRAR_ROLE granted to SignedRegistrar");

        vm.stopBroadcast();
    }
}
