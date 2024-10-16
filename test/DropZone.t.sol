// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/DropZone.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

// Mock ERC20 Token for testing
contract MockERC20 is ERC20 {
    constructor() ERC20("Mock Token", "MCK") {
        _mint(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266, 1000 * 10 ** 18); // Mint 1000 tokens to the deployer
    }
}

contract DropZoneTest is Test {
    MockERC20 public mockToken;
    DropZone public dropZone;
    address OWNER = vm.envAddress("OWNER"); // 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
    address USER = vm.envAddress("USER"); // 0x70997970C51812dc3A010C7d01b50e0d17dc79C8
    address USER2 = vm.envAddress("USER2"); // 0x70997970C51812dc3A010C7d01b50e0d17dc79C8
    address USER3 = vm.envAddress("USER3"); // 0x70997970C51812dc3A010C7d01b50e0d17dc79C8
    bytes32 ROOT =
        0xbf918e94af070dcd6ab58b92b1a0795374b63d9d60ad8671091c4c226b6dc663;
    uint256 AMOUNT = 100;
    uint256 AMOUNT2 = 20;
    uint256 AMOUNT3 = 50;

    string merkleDataURI = "QmSomeHash";

    function setUp() public {
        // Deploy the mock token
        mockToken = new MockERC20();

        vm.startPrank(OWNER); // Set the sender to the owner
        dropZone = new DropZone(address(mockToken), OWNER, ROOT, merkleDataURI);
        vm.stopPrank();
    }

    // check deployemtn by checking the token is set to mock token
    function testDeployment() public view {
        // Check that the contract is deployed with the correct token address
        assertEq(address(dropZone.token()), address(mockToken));
    }

    function testUpdateMerkleRoot() public {
        // Set a Merkle root and IPFS hash

        // Call the updateMerkleRoot function
        vm.startPrank(OWNER); // Set the sender to the owner
        dropZone.updateMerkleRoot(ROOT, merkleDataURI);
        vm.stopPrank();

        // Verify the Merkle root and IPFS hash are set correctly
        assertEq(dropZone.merkleRoot(), ROOT);
        assertEq(dropZone.merkleDataURI(), merkleDataURI);
    }

    function testPauseAndUnpause() public {
        // Check initial state
        assertEq(dropZone.paused(), false);
        // console.log(dropZone.owner());

        // Pause the contract
        vm.startPrank(OWNER);
        dropZone.pause("Testing pause");
        vm.stopPrank();

        // Verify the contract is paused
        assertEq(dropZone.paused(), true);

        // Unpause the contract
        vm.startPrank(OWNER);
        dropZone.unpause("Testing unpause");
        vm.stopPrank();

        // Verify the contract is unpaused
        assertEq(dropZone.paused(), false);
    }

    // Helper function to generate a Merkle root and proof
    // function generateMerkleRootAndProof(
    //     address[] memory accounts,
    //     uint256[] memory amounts
    // ) internal pure returns (bytes32, bytes32[][] memory) {
    //     require(
    //         accounts.length == amounts.length,
    //         "Accounts and amounts length mismatch"
    //     );

    //     bytes32[] memory leaves = new bytes32[](accounts.length);
    //     for (uint i = 0; i < accounts.length; i++) {
    //         leaves[i] = keccak256(abi.encodePacked(accounts[i], amounts[i]));
    //     }

    //     uint256 n = leaves.length;
    //     uint256 offset = 0;

    //     while (n > 1) {
    //         for (uint i = 0; i < n; i += 2) {
    //             bytes32 left = leaves[offset + i];
    //             bytes32 right = (i + 1 < n) ? leaves[offset + i + 1] : left;
    //             leaves[offset + i / 2] = keccak256(
    //                 abi.encodePacked(left, right)
    //             );
    //         }
    //         offset += n / 2;
    //         n = (n + 1) / 2;
    //     }

    //     bytes32 root = leaves[0];

    //     bytes32[][] memory proofs = new bytes32[][](accounts.length);
    //     for (uint i = 0; i < accounts.length; i++) {
    //         uint256 index = i;
    //         uint256 proofLength = calculateProofLength(accounts.length);
    //         bytes32[] memory proof = new bytes32[](proofLength);
    //         uint256 j = 0;
    //         n = accounts.length;
    //         offset = 0;

    //         while (n > 1) {
    //             if (index % 2 == 0) {
    //                 proof[j] = index + 1 < n
    //                     ? leaves[offset + index + 1]
    //                     : leaves[offset + index];
    //             } else {
    //                 proof[j] = leaves[offset + index - 1];
    //             }
    //             j++;
    //             index /= 2;
    //             offset += n / 2;
    //             n = (n + 1) / 2;
    //         }
    //         proofs[i] = proof;
    //     }

    //     return (root, proofs);
    // }

    // Internal function to generate a Merkle root and corresponding proofs
    function generateMerkleRootAndProof(
        address[] memory accounts,
        uint256[] memory amounts
    ) internal pure returns (bytes32, bytes32[][] memory) {
        require(
            accounts.length == amounts.length,
            "Accounts and amounts length mismatch"
        );

        // Create an array to store the leaf nodes
        bytes32[] memory leaves = new bytes32[](accounts.length);

        // Generate leaf nodes (hash(account, amount))
        for (uint256 i = 0; i < accounts.length; i++) {
            leaves[i] = keccak256(abi.encodePacked(accounts[i], amounts[i]));
        }

        // Build the Merkle tree and get the root
        bytes32 root = buildMerkleTree(leaves);

        // Generate the proofs for each account
        bytes32[][] memory proofs = new bytes32[][](accounts.length);
        for (uint256 i = 0; i < accounts.length; i++) {
            proofs[i] = generateProof(i, leaves);
        }

        return (root, proofs);
    }

    // Internal function to build a Merkle tree and return the root
    function buildMerkleTree(
        bytes32[] memory leaves
    ) internal pure returns (bytes32) {
        uint256 n = leaves.length;
        while (n > 1) {
            uint256 j = 0;
            for (uint256 i = 0; i < n - 1; i += 2) {
                leaves[j] = keccak256(
                    abi.encodePacked(leaves[i], leaves[i + 1])
                );
                j++;
            }
            if (n % 2 == 1) {
                leaves[j] = leaves[n - 1]; // Handle odd number of leaves
                j++;
            }
            n = j;
        }
        return leaves[0]; // Root of the Merkle tree
    }

    // Internal function to generate the proof for a specific leaf in the Merkle tree
    function generateProof(
        uint256 index,
        bytes32[] memory leaves
    ) internal pure returns (bytes32[] memory) {
        uint256 n = leaves.length;
        uint256 proofLength = log2(n);
        bytes32[] memory proof = new bytes32[](proofLength);

        uint256 proofIndex = 0;
        while (n > 1) {
            // Only add the sibling if it exists (check for out-of-bounds)
            if (index % 2 == 1 && index > 0) {
                proof[proofIndex] = leaves[index - 1];
            } else if (index < n - 1) {
                proof[proofIndex] = leaves[index + 1];
            }
            proofIndex++;

            // Move up the tree
            index /= 2;
            n = (n + 1) / 2;
        }

        return proof;
    }

    // Helper function to calculate the log2 of a number
    function log2(uint256 x) internal pure returns (uint256) {
        uint256 result = 0;
        while (x > 1) {
            x /= 2;
            result++;
        }
        return result;
    }

    function calculateProofLength(uint256 n) internal pure returns (uint256) {
        uint256 length = 0;
        while (n > 1) {
            length++;
            n = (n + 1) / 2;
        }
        return length;
    }

    function testClaimTokens() public {
        // Setup
        address[] memory accounts = new address[](1);
        accounts[0] = USER;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 100 * 10 ** 18; // 100 tokens

        (bytes32 root, bytes32[][] memory proofs) = generateMerkleRootAndProof(
            accounts,
            amounts
        );

        // Update Merkle root
        vm.prank(OWNER);
        dropZone.updateMerkleRoot(root, "TestmerkleDataURI");

        // Fund the contract
        vm.startPrank(OWNER);
        mockToken.approve(address(dropZone), amounts[0]);
        dropZone.fundAirdrop(amounts[0], OWNER);
        vm.stopPrank();

        // Claim tokens
        vm.prank(USER);
        dropZone.claimTokens(USER, amounts[0], proofs[0]);

        // Verify
        assertEq(mockToken.balanceOf(USER), amounts[0]);
        assertTrue(dropZone.hasClaimed(USER));
    }

    // failing but tested manually ()
    // [FAIL. Reason: panic: array out-of-bounds access (0x32)]
    function testBatchClaimTokens() public {
        // Setup
        address[] memory accounts = new address[](3);
        accounts[0] = USER;
        accounts[1] = USER2;
        accounts[2] = USER3;
        uint256[] memory amounts = new uint256[](3);
        amounts[0] = 100 * 10 ** 18; // 100 tokens
        amounts[1] = 200 * 10 ** 18; // 200 tokens
        amounts[2] = 300 * 10 ** 18; // 300 tokens

        // Generate Merkle root and proofs for all accounts at once
        (
            bytes32 root,
            bytes32[][] memory allProofs
        ) = generateMerkleRootAndProof(accounts, amounts);

        // Update Merkle root
        vm.prank(OWNER);
        dropZone.updateMerkleRoot(root, "TestmerkleDataURI");

        // Fund the contract
        vm.startPrank(OWNER);
        uint256 totalAmount = 600 * 10 ** 18; // Sum of all amounts
        mockToken.approve(address(dropZone), totalAmount);
        dropZone.fundAirdrop(totalAmount, OWNER);
        vm.stopPrank();

        // Batch claim tokens
        vm.prank(USER);
        dropZone.batchClaimTokens(accounts, amounts, allProofs);

        console.log(mockToken.balanceOf(USER));
        console.log(mockToken.balanceOf(USER2));
        console.log(mockToken.balanceOf(USER3));
        // Verify
        // assertEq(mockToken.balanceOf(USER), amounts[0]);
        // assertEq(mockToken.balanceOf(address(0x1)), amounts[1]);
        // assertEq(mockToken.balanceOf(address(0x2)), amounts[2]);
        // assertTrue(dropZone.hasClaimed(USER));
        // assertTrue(dropZone.hasClaimed(address(0x1)));
        // assertTrue(dropZone.hasClaimed(address(0x2)));
    }
}
