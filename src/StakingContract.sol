// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title StakingContract
 * @notice Implements staking and slashing mechanisms to help prevent Sybil attacks.
 *         Users must stake ETH; funds can be withdrawn later. Admins can slash stakes if needed.
 */
contract StakingContract is AccessControl, ReentrancyGuard {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    // Minimum stake amount required (e.g., 0.01 ETH).
    uint256 public constant MINIMUM_STAKE = 0.01 ether;

    // Mapping from user address to staked balance in wei.
    mapping(address => uint256) public stakes;

    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event Slashed(address indexed user, uint256 amount);

    /**
     * @notice Constructor that sets the deployer as the admin.
     */
    constructor() {
        _grantRole(ADMIN_ROLE, msg.sender);
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /**
     * @notice Stake ETH to participate. The amount staked must be at least MINIMUM_STAKE.
     */
    function stake() external payable nonReentrant {
        require(msg.value >= MINIMUM_STAKE, "Stake amount is below minimum requirement");
        stakes[msg.sender] += msg.value;
        emit Staked(msg.sender, msg.value);
    }

    /**
     * @notice Withdraw a specified amount of staked ETH.
     * @param amount The amount to withdraw (in wei).
     */
    function withdraw(uint256 amount) external nonReentrant {
        require(stakes[msg.sender] >= amount, "Insufficient stake");
        stakes[msg.sender] -= amount;
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Withdrawal failed");
        emit Withdrawn(msg.sender, amount);
    }

    /**
     * @notice Slash (penalize) a user’s stake by a specified amount. Only ADMIN_ROLE can call.
     * @param user The address whose stake is to be slashed.
     * @param amount The amount to slash (in wei).
     */
    function slash(address user, uint256 amount) external nonReentrant onlyRole(ADMIN_ROLE) {
        require(stakes[user] >= amount, "User does not have enough stake to slash");
        stakes[user] -= amount;
        // In this implementation, slashed funds remain in the contract.
        emit Slashed(user, amount);
    }
    
    /**
     * @notice Fallback receive function to accept ETH.
     */
    receive() external payable {
        require(msg.value >= MINIMUM_STAKE, "Stake amount is below minimum requirement");
        stakes[msg.sender] += msg.value;
        emit Staked(msg.sender, msg.value);
    }
}