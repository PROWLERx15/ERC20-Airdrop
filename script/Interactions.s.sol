// // SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import { Script } from "forge-std/Script.sol";
import { DevOpsTools } from "foundry-devops/src/DevOpsTools.sol";
import { Airdrop } from "src/Airdrop.sol";

contract ClaimAirdrop is Script {
    error Interactions_ClaimAirdrop__InvalidSignatureLength();

    address CLAIMING_ADDRESS = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    uint256 CLAIMING_AMOUNT = 25 * 1e18;
    bytes32 proofOne = 0xd1445c931158119b00449ffcac3c947d028c0c359c34a6646d95962b3b55c6ad;
    bytes32 proofTwo = 0xe5ebd1e1b5a5478a944ecab36a9a954ac3b6b8216875f6524caa7a1d87096576;
    bytes32[] public PROOF = [proofOne, proofTwo];
    bytes private SIGNATURE =
        hex"5332d816cfd2b76c2f83c8a3e0d81a4cc979b9d42e0f2a1a2f2484e6dd72dd69648002851cb9a72f59027fe87c8deea17030c59d3c739e93847d50d51aa2cd8c1c";

    function splitSignature(bytes memory signature) public pure returns (uint8 v, bytes32 r, bytes32 s) {
        if (signature.length != 65) {
            revert Interactions_ClaimAirdrop__InvalidSignatureLength();
        }
        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := byte(0, mload(add(signature, 96)))
        }

        return (v, r, s);
    }

    function claimAirdrop(address airdrop) public {
        vm.startBroadcast();
        (uint8 v, bytes32 r, bytes32 s) = splitSignature(SIGNATURE);
        Airdrop(airdrop).claimAirdrop(CLAIMING_ADDRESS, CLAIMING_AMOUNT, PROOF, v, r, s);
        vm.stopBroadcast();
    }

    function run() external {
        address mostRecentlyDeployedAirdropContract = DevOpsTools.get_most_recent_deployment("Airdrop", block.chainid);
        claimAirdrop(mostRecentlyDeployedAirdropContract);
    }
}

// script to create signature using foundry

// 5332d816cfd2b76c2f83c8a3e0d81a4cc979b9d42e0f2a1a2f2484e6dd72dd69648002851cb9a72f59027fe87c8deea17030c59d3c739e93847d50d51aa2cd8c1c
// first 32 bytes -> r
// second 32 bytes -> s
// final byte -> v

// When working with functions from libraries like OpenZeppelin or other APIs,
// the signature format typically follows the order _v,r,s_ instead of the _r,s,v_ we used in this lesson.
