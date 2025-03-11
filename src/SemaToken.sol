// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title SemaToken
 * @notice ERC‐20 token with role‐based minting and burning. Total supply is 8M tokens.
 */
contract SemaToken is ERC20, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant ADMIN_ROLE  = keccak256("ADMIN_ROLE");

    /**
     * @notice Constructor that sets up roles and mints initial supply.
     * @param name Token name.
     * @param symbol Token symbol.
     * @param adminAddress Address to receive the admin role and initial token supply.
     */
    constructor(
        string memory name, 
        string memory symbol, 
        address adminAddress
    ) ERC20(name, symbol) {
        // Grant the contract deployer the admin role
        _grantRole(ADMIN_ROLE, adminAddress);

        // Optional: The admin might also be a minter
        _grantRole(MINTER_ROLE, adminAddress);

        // Set admin role as the role-admin for all roles
        _setRoleAdmin(MINTER_ROLE, ADMIN_ROLE);
        // Optional for pausing:
        // _setRoleAdmin(PAUSER_ROLE, ADMIN_ROLE);
        // Mint initial supply: 8,000,000 tokens (with standard 18 decimals).
        _mint(adminAddress, 8_000_000 * 10 ** decimals());
    }

    /**
     * @notice Mint new tokens. Only addresses with MINTER_ROLE can call.
     * @param to Recipient address.
     * @param amount Number of tokens to mint (in smallest units).
     */
    function mint(address to, uint256 amount) external onlyRole(MINTER_ROLE) {
         _mint(to, amount);
    }

    /**
     * @notice Burn tokens held by the caller.
     * @param amount Number of tokens to burn (in smallest units).
     */
    function burn(uint256 amount) external {
         _burn(msg.sender, amount);
    }
}