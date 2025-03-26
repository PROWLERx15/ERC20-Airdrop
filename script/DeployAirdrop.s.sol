// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Script } from "forge-std/Script.sol";
import { Airdrop, IERC20 } from "src/Airdrop.sol";
import { Token } from "src/Token.sol";

contract DeployAirdrop is Script {
    bytes32 private constant ROOT = 0xaa5d581231e596618465a56aa0f5870ba6e20785fe436d5bfb82b08662ccc7c4;
    uint256 private AMOUNT_TO_TRANSFER = 4 * 25 * 1e18; // 4 claimers, 25 tokens each

    function deployAirdrop() public returns (Airdrop, Token) {
        vm.startBroadcast();
        Token token = new Token();
        Airdrop airdrop = new Airdrop(ROOT, IERC20(token));

        // Mint and Transfer Tokens to Airdrop Contract
        token.mint(token.owner(), AMOUNT_TO_TRANSFER);
        IERC20(token).transfer(address(airdrop), AMOUNT_TO_TRANSFER);

        vm.stopBroadcast();
        return (airdrop, token);
    }

    function run() external returns (Airdrop, Token) {
        return deployAirdrop();
    }
}
