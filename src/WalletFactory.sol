// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import {WalletImplementation} from "./WalletImplementation.sol";


/**
 * @title WalletFactory
 * @notice Creates wallets for users using a minimal proxy pattern.
 *         There are two types of wallets: parent (for content creators or main user identity)
 *         and child (for interactions/engagements). The contract uses a counter starting from 1
 *         to avoid ambiguity with default values.
 */
contract WalletFactory is AccessControl {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    // Address of the wallet implementation used for cloning.
    WalletImplementation public walletImplementation;

    // Next wallet ID (starting at 1).
    uint256 private nextWalletId = 1;

    struct WalletDetail {
        uint256 id;
        address walletAddress;
        uint256 parentId; // Zero indicates a parent wallet.
        string role;    // "parent" or "child"
        address owner;
    }
    // Mapping from wallet ID to wallet details.
    mapping(uint256 => WalletDetail) public wallets;

    // Mapping from parent wallet ID to the list of its child wallet IDs.
    mapping(uint256 => uint256[]) public parentChildMapping;

    // Mapping from owner address to their parent wallet ID (nonzero indicates existence).
    mapping(address => uint256) public parentWalletOfOwner;

    event WalletCreated(uint256 indexed walletId, address indexed walletAddress, uint256 parentId, string role);

    /**
     * @notice Constructor sets the wallet implementation address.
     * @param _walletImplementation The address of the implementation contract to clone.
     */
    constructor(WalletImplementation _walletImplementation) {
        walletImplementation = WalletImplementation(_walletImplementation);
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
    }

    /**
     * @notice Create a new parent wallet for a given user. Only ADMIN_ROLE can call.
     * @param owner The address that will own the new wallet.
     * @return newWalletId The new parent wallet's ID.
     */
    function createParentWallet(address owner) external onlyRole(ADMIN_ROLE) returns (uint256) {
        require(parentWalletOfOwner[owner] == 0, "Parent wallet already exists for this owner");

        uint256 newWalletId = nextWalletId;
        nextWalletId++;

        // Generate deterministic salt based on owner and wallet ID.
        bytes32 salt = keccak256(abi.encodePacked(owner, block.timestamp, newWalletId));
        address walletAddr = Clones.cloneDeterministic(address(walletImplementation), salt);

        // Initialize the wallet clone.
        WalletImplementation(walletAddr).initialize(owner, newWalletId, "parent");

        // Save wallet details.
        wallets[newWalletId] = WalletDetail({
            id: newWalletId,
            walletAddress: walletAddr,
            parentId: 0,
            role: "parent",
            owner: owner
        });
        parentWalletOfOwner[owner] = newWalletId;

        emit WalletCreated(newWalletId, walletAddr, 0, "parent");
        return newWalletId;
    }

    /**
     * @notice Create a new child wallet linked to an existing parent wallet.
     *         Only addresses with MINTER_ROLE can call.
     * @param parentId The parent wallet's ID.
     * @param owner The address that will own the new child wallet.
     * @return newWalletId The new child wallet's ID.
     */
    function createChildWallet(uint256 parentId, address owner) external onlyRole(MINTER_ROLE) returns (uint256) {
        require(wallets[parentId].owner != address(0), "Parent wallet does not exist");

        uint256 newWalletId = nextWalletId;
        nextWalletId++;

        bytes32 salt = keccak256(abi.encodePacked(owner, block.timestamp, newWalletId));
        address walletAddr = Clones.cloneDeterministic(address(walletImplementation), salt);

        // Initialize the wallet clone.
        WalletImplementation(walletAddr).initialize(owner, newWalletId, "child");

        wallets[newWalletId] = WalletDetail({
            id: newWalletId,
            walletAddress: walletAddr,
            parentId: parentId,
            role: "child",
            owner: owner
        });
        parentChildMapping[parentId].push(newWalletId);

        emit WalletCreated(newWalletId, walletAddr, parentId, "child");
        return newWalletId;
    }

    /**
     * @notice Retrieve all child wallet IDs for a given parent wallet.
     * @param parentId The parent wallet's ID.
     * @return An array of child wallet IDs.
     */
    function getChildWallets(uint256 parentId) external view returns (uint256[] memory) {
        return parentChildMapping[parentId];
    }

    /**
     * @notice Grant MINTER_ROLE to an address.
     * @param account The address to grant the MINTER_ROLE.
     */
    function addMinter(address account) external onlyRole(ADMIN_ROLE) {
        grantRole(MINTER_ROLE, account);
    }

    /**
     * @notice Revoke MINTER_ROLE from an address.
     * @param account The address to revoke the MINTER_ROLE from.
     */
    function removeMinter(address account) external onlyRole(ADMIN_ROLE) {
        revokeRole(MINTER_ROLE, account);
    }
}

