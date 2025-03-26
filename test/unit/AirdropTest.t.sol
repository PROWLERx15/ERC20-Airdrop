// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Test, console } from "forge-std/Test.sol";
import { Airdrop } from "src/Airdrop.sol";
import { Token } from "src/Token.sol";
import { DeployAirdrop } from "script/DeployAirdrop.s.sol";
import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import { IERC20, SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract AirdropTest is Test {
    using SafeERC20 for IERC20;

    Airdrop public airdrop;
    Token public token;
    DeployAirdrop public deployer;

    bytes32 public constant ROOT = 0xaa5d581231e596618465a56aa0f5870ba6e20785fe436d5bfb82b08662ccc7c4;
    uint256 public constant AMOUNT_TO_CLAIM = 25 * 1e18;
    uint256 public constant TOKENS_TO_MINT = 4 * AMOUNT_TO_CLAIM;

    bytes32 proofOne = 0x0fd7c981d39bece61f7499702bf59b3114a90e66b51ba2c53abdf7b62986c00a;
    bytes32 proofTwo = 0xe5ebd1e1b5a5478a944ecab36a9a954ac3b6b8216875f6524caa7a1d87096576;
    bytes32[] public PROOF = [proofOne, proofTwo];

    bytes32 Invalid_proofOne = 0xe5ebd1e1b5a5478a944ecab36a9a954ac3b6b8216875f6524caa7a1d87096576;
    bytes32 Invalid_proofTwo = 0x0fd7c981d39bece61f7499702bf59b3114a90e66b51ba2c53abdf7b62986c00a;
    bytes32[] public INVALID_PROOF = [Invalid_proofOne, Invalid_proofTwo];

    address public gasPayer;
    address user;
    uint256 userPrivateKey;

    function setUp() public {
        token = new Token();
        airdrop = new Airdrop(ROOT, token);
        token.mint(token.owner(), TOKENS_TO_MINT);
        token.transfer(address(airdrop), TOKENS_TO_MINT);
        (user, userPrivateKey) = makeAddrAndKey("user");
        console.log("Address of Claimer: ", user);
        console.log("Private Key of Claimer: ", userPrivateKey);

        gasPayer = makeAddr("gasPayer");
        console.log("Address of Gas Payer: ", gasPayer);
    }

    function signMessage(address account, uint256 privKey) public returns (uint8 v, bytes32 r, bytes32 s) {
        bytes32 hashedMessage = airdrop.getMessageHash(user, AMOUNT_TO_CLAIM);

        // sign the message
        vm.prank(account);
        (v, r, s) = vm.sign(privKey, hashedMessage);
        vm.stopPrank();
    }

    function testUserCanClaim() public {
        uint256 startingBalance = token.balanceOf(user);

        // sign the message
        (uint8 v, bytes32 r, bytes32 s) = signMessage(user, userPrivateKey);

        // gasPayer calls the claim using the signed message
        vm.prank(gasPayer);
        airdrop.claimAirdrop(user, AMOUNT_TO_CLAIM, PROOF, v, r, s);

        uint256 endingBalance = token.balanceOf(user);
        assertEq(endingBalance - startingBalance, AMOUNT_TO_CLAIM);
        vm.stopPrank();
    }

    function testClaimStatusIsValid() public {
        bool claimStatus_False = airdrop.getClaimStatus(user);
        assertFalse(claimStatus_False);

        vm.prank(user);
        (uint8 v, bytes32 r, bytes32 s) = signMessage(user, userPrivateKey);
        airdrop.claimAirdrop(user, AMOUNT_TO_CLAIM, PROOF, v, r, s);
        vm.stopPrank();

        bool claimStatus_True = airdrop.getClaimStatus(user);
        assertTrue(claimStatus_True);
    }

    function testMerkleRootIsValid() public view {
        bytes32 expectedRoot = ROOT;
        bytes32 actualRoot = airdrop.getMerkleRoot();
        assertEq(expectedRoot, actualRoot);
    }

    function testAirdropTokenIsValid() public view {
        address expectedAirdropToken = address(token);
        address actualAirdropToken = address(airdrop.getAirdropToken());
        assertEq(expectedAirdropToken, actualAirdropToken);
    }

    function testRevertOnInvalidSignature() public {
        address revertUser;
        uint256 revertUserPrivateKey;
        (revertUser, revertUserPrivateKey) = makeAddrAndKey("revert");

        vm.prank(revertUser);
        (uint8 v, bytes32 r, bytes32 s) = signMessage(revertUser, revertUserPrivateKey);
        vm.expectRevert(Airdrop.Airdrop__InvalidSignature.selector);
        airdrop.claimAirdrop(user, AMOUNT_TO_CLAIM, PROOF, v, r, s);
        vm.stopPrank();
    }

    function testCanClaimOnlyOnce() public {
        vm.prank(user);
        (uint8 v, bytes32 r, bytes32 s) = signMessage(user, userPrivateKey);
        airdrop.claimAirdrop(user, AMOUNT_TO_CLAIM, PROOF, v, r, s);
        vm.stopPrank();

        vm.prank(user);
        vm.expectRevert(Airdrop.Airdrop__AlreadyClaimed.selector);
        airdrop.claimAirdrop(user, AMOUNT_TO_CLAIM, PROOF, v, r, s);
        vm.stopPrank();
    }

    function testRevertOnInvalidProof() public {
        vm.prank(user);
        (uint8 v, bytes32 r, bytes32 s) = signMessage(user, userPrivateKey);
        vm.expectRevert(Airdrop.Airdrop__InvalidMerkleProof.selector);
        airdrop.claimAirdrop(user, AMOUNT_TO_CLAIM, INVALID_PROOF, v, r, s);
        vm.stopPrank();
    }
}
