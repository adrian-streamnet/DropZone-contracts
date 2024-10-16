// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./DropZone.sol"; // Importing the DropZone contract

contract DropZoneFactory {
    // Mapping from deployer address to their deployed DropZone contracts
    mapping(address => address[]) public deployedDrops;

    event DropDeployed(
        address indexed deployer,
        address dropAddress,
        bytes32 salt
    );

    // Function to deploy a new DropZone contract using a user-provided salt
    function deployDropZone(
        address _token,
        address _owner,
        bytes32 _merkleRoot,
        string memory _merkleDataUri,
        bytes32 _salt
    ) public returns (address) {
        // Deploy the contract using CREATE2 and return the new contract's address
        address newDrop = _deploy(
            _token,
            _owner,
            _merkleRoot,
            _merkleDataUri,
            _salt
        );

        // Store the new contract in the mapping
        deployedDrops[_owner].push(newDrop);

        emit DropDeployed(_owner, newDrop, _salt);

        return newDrop;
    }

    // Function to retrieve all deployed contracts by a user
    function getDeployedDrops(
        address _deployer
    ) public view returns (address[] memory) {
        return deployedDrops[_deployer];
    }

    // Internal function to handle deployment using CREATE2
    function _deploy(
        address _token,
        address _owner,
        bytes32 _merkleRoot,
        string memory _merkleDataUri,
        bytes32 _salt
    ) internal returns (address) {
        // Get the bytecode of the DropZone contract
        bytes memory bytecode = abi.encodePacked(
            type(DropZone).creationCode,
            abi.encode(_token, _owner, _merkleRoot, _merkleDataUri)
        );

        // Compute the address where the contract will be deployed
        address addr;

        // Use CREATE2 to deploy the contract
        assembly {
            addr := create2(0, add(bytecode, 0x20), mload(bytecode), _salt)
            if iszero(extcodesize(addr)) {
                revert(0, 0)
            }
        }

        return addr;
    }

    // Function to compute the future address of a DropZone contract with a known salt
    function computeAddress(
        address _token,
        address _owner,
        bytes32 _merkleRoot,
        string memory _merkleDataUri,
        bytes32 _salt
    ) public view returns (address) {
        bytes memory bytecode = abi.encodePacked(
            type(DropZone).creationCode,
            abi.encode(_token, _owner, _merkleRoot, _merkleDataUri)
        );

        bytes32 hash = keccak256(
            abi.encodePacked(
                bytes1(0xff), // CREATE2 prefix
                address(this), // Factory address
                _salt, // Salt
                keccak256(bytecode) // Bytecode hash
            )
        );

        return address(uint160(uint256(hash)));
    }
}
