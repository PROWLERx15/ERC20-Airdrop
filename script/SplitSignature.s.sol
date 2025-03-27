// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import { Script } from "forge-std/Script.sol";
import { console } from "forge-std/console.sol";

contract SplitSignature is Script {
    error SplitSignature__InvalidSignatureLength();

    function _SplitSignature(bytes memory signature) internal pure returns (uint8 v, bytes32 r, bytes32 s) {
        if (signature.length != 65) {
            revert SplitSignature__InvalidSignatureLength();
        }
        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := byte(0, mload(add(signature, 96)))
        }

        return (v, r, s);
    }

    function run() public view {
        string memory signature = vm.readFile("signature.txt");
        bytes memory signatureBytes = vm.parseBytes(signature);
        (uint8 v, bytes32 r, bytes32 s) = _SplitSignature(signatureBytes);
        console.log("v value: ");
        console.log(v);
        console.log("r value: ");
        console.logBytes32(r);
        console.log("s value: ");
        console.logBytes32(s);
    }
}
