// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/DropZoneFactory.sol";

contract DeployDropZone is Script {
    function run() external {
        // Start broadcasting the transaction
        vm.startBroadcast();

        // Deploy the DropZone contract
        DropZoneFactory factory = new DropZoneFactory();

        // Log the deployed contract address
        console.log("DropZone factory deployed at:", address(factory));

        // Stop broadcasting
        vm.stopBroadcast();
    }
}
