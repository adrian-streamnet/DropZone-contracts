// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/DropZone.sol"; // Adjust the import path according to your project structure;

contract DeployDropZone is Script {
    function run() external {
        // Specify the address of the token you want to use for the airdrop
        // address tokenAddress = 0x4200000000000000000000000000000000000042; // Replace with the actual token address
        address tokenAddress = 0x969C1CeE57332E7e614c849Da2b6EfBC81f3fd60; // mock TRR token address
        address OWNER = vm.envAddress("OWNER"); // 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
        bytes32 ROOT = 0xbf918e94af070dcd6ab58b92b1a0795374b63d9d60ad8671091c4c226b6dc663;
        string memory merkleDataURI = "QmSomeHash";

        // Start broadcasting the transaction
        vm.startBroadcast();

        // Deploy the DropZone contract
        DropZone tr = new DropZone(tokenAddress, OWNER, ROOT, merkleDataURI);

        // Log the deployed contract address
        console.log("DropZone deployed at:", address(tr));

        // Stop broadcasting
        vm.stopBroadcast();
    }
}
