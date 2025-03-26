// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/* imports */
import { Token } from "src/Token.sol";
import { IERC20, SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { MerkleProof } from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import { EIP712 } from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/**
 * @title Airdrop Contract
 * @author PROWLERx15
 * @notice This contract allows users to claim Airdrop Tokens. It uses Merkle Proof verification and EIP712 signatures.
 */
contract Airdrop is EIP712 {
    /* interfaces, libraries, contract */
    using SafeERC20 for IERC20;

    /* errors */
    error Airdrop__InvalidMerkleProof();
    error Airdrop__AlreadyClaimed();
    error Airdrop__InvalidSignature();

    /* Type declarations */
    struct AirdropClaim {
        address account;
        uint256 amount;
    }

    /* State variables */
    address[] airdropClaimers;
    bytes32 private constant MESSAGE_TYPEHASH = keccak256("AirdropClaim(address account, uint256 amount)");
    bytes32 private immutable i_merkleRoot;
    IERC20 private immutable i_airdropToken;
    mapping(address claimer => bool claimed) private s_hasClaimed;

    /* Events */
    event Claim(address account, uint256 amount);

    /* Modifiers */
    modifier notClaimed(address account) {
        if (s_hasClaimed[account]) {
            revert Airdrop__AlreadyClaimed();
        }
        _;
    }

    /* Functions */

    /* constructor */
    constructor(bytes32 _merkleRoot, IERC20 _airdropToken) EIP712("ERC20 Airdrop", "1") {
        i_merkleRoot = _merkleRoot;
        i_airdropToken = _airdropToken;
    }

    /* external */

    //  Allows eligible users to claim their airdrop.
    function claimAirdrop(
        address account,
        uint256 amount,
        bytes32[] calldata merkleProof,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        external
        notClaimed(account)
    {
        // Verify the signature
        if (!_isValidSignature(account, getMessageHash(account, amount), v, r, s)) {
            revert Airdrop__InvalidSignature();
        }

        // Calculate the leaf node hash
        // leaf -> double hash (account + amount)
        // double hash to avoid collisions and prevent second pre-image attacks
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(account, amount))));

        // verify the merkle proof
        if (!MerkleProof.verify(merkleProof, i_merkleRoot, leaf)) {
            revert Airdrop__InvalidMerkleProof();
        }

        s_hasClaimed[account] = true; // update user's claim status to prevent claiming more than once.
        emit Claim(account, amount);
        i_airdropToken.safeTransfer(account, amount);
    }

    /* internal & private view & pure functions */
    function _isValidSignature(
        address account,
        bytes32 digest,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        internal
        pure
        returns (bool)
    {
        (address actualSigner,,) = ECDSA.tryRecover(digest, v, r, s);
        return (actualSigner == account);
    }

    /* external & public view & pure functions */
    function getMessageHash(address _account, uint256 _amount) public view returns (bytes32) {
        return _hashTypedDataV4(
            keccak256(abi.encode(MESSAGE_TYPEHASH, AirdropClaim({ account: _account, amount: _amount })))
        );
    }

    function getMerkleRoot() external view returns (bytes32) {
        return i_merkleRoot;
    }

    function getAirdropToken() external view returns (IERC20) {
        return i_airdropToken;
    }

    function getClaimStatus(address account) external view returns (bool) {
        return s_hasClaimed[account];
    }
}
