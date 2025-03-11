// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "forge-std/Test.sol";
import "../src/StakingContract.sol";

contract StakingContractTest is Test {
    StakingContract public stakingContract;
    address public admin;
    address public user1;
    address public user2;
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    
    function setUp() public {
        // Set up accounts
        admin = address(this);
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
        
        // Fund test accounts
        vm.deal(user1, 1 ether);
        vm.deal(user2, 1 ether);
        
        // Deploy contract
        stakingContract = new StakingContract();
    }
    
    function test_Deployment() public view {
        // Check if admin role is assigned to deployer
        assertTrue(stakingContract.hasRole(ADMIN_ROLE, admin));
        
        // Check minimum stake amount
        assertEq(stakingContract.MINIMUM_STAKE(), 0.01 ether);
    }
    
    function test_Stake() public {
        // Stake from user1
        vm.prank(user1);
        stakingContract.stake{value: 0.05 ether}();
        
        // Check if stake was recorded
        assertEq(stakingContract.stakes(user1), 0.05 ether);
    }
    
    function test_RevertWhen_StakeBelowMinimum() public {
        // Try to stake below minimum
        vm.prank(user1);
        vm.expectRevert("Stake amount is below minimum requirement");
        stakingContract.stake{value: 0.005 ether}();
    }
    
    function test_StakeEmitsEvent() public {
        // Prepare to check for event
        vm.prank(user1);
        vm.expectEmit(true, false, false, true);
        emit StakingContract.Staked(user1, 0.05 ether);
        
        // Perform stake
        stakingContract.stake{value: 0.05 ether}();
    }
    
    function test_Withdraw() public {
        // First stake some ETH
        vm.prank(user1);
        stakingContract.stake{value: 0.05 ether}();
        
        // Then withdraw part of it
        vm.prank(user1);
        stakingContract.withdraw(0.02 ether);
        
        // Check stake balance
        assertEq(stakingContract.stakes(user1), 0.03 ether);
    }
    
    function test_RevertWhen_WithdrawMoreThanStaked() public {
        // First stake some ETH
        vm.prank(user1);
        stakingContract.stake{value: 0.05 ether}();
        
        // Try to withdraw more than staked
        vm.prank(user1);
        vm.expectRevert("Insufficient stake");
        stakingContract.withdraw(0.1 ether);
    }
    
    function test_WithdrawEmitsEvent() public {
        // First stake some ETH
        vm.prank(user1);
        stakingContract.stake{value: 0.05 ether}();
        
        // Prepare to check for event
        vm.prank(user1);
        vm.expectEmit(true, false, false, true);
        emit StakingContract.Withdrawn(user1, 0.02 ether);
        
        // Perform withdrawal
        stakingContract.withdraw(0.02 ether);
    }
    
    function test_WithdrawTransfersETH() public {
        // First stake some ETH
        vm.prank(user1);
        stakingContract.stake{value: 0.05 ether}();
        
        // Record balance before withdrawal
        uint256 balanceBefore = user1.balance;
        
        // Perform withdrawal
        vm.prank(user1);
        stakingContract.withdraw(0.02 ether);
        
        // Check balance after withdrawal
        assertEq(user1.balance, balanceBefore + 0.02 ether);
    }
    
    function test_Slash() public {
        // First have user1 stake
        vm.prank(user1);
        stakingContract.stake{value: 0.05 ether}();
        
        // Admin slashes user1
        vm.prank(admin);
        stakingContract.slash(user1, 0.01 ether);
        
        // Check if stake was reduced
        assertEq(stakingContract.stakes(user1), 0.04 ether);
    }
    
    function test_RevertWhen_SlashMoreThanStaked() public {
        // First have user1 stake
        vm.prank(user1);
        stakingContract.stake{value: 0.05 ether}();
        
        // Try to slash more than staked
        vm.prank(admin);
        vm.expectRevert("User does not have enough stake to slash");
        stakingContract.slash(user1, 0.1 ether);
    }
    
    function test_RevertWhen_NonAdminSlashes() public {
        // First have user1 stake
        vm.prank(user1);
        stakingContract.stake{value: 0.05 ether}();
        
        // User2 tries to slash user1 (should fail)
        vm.prank(user2);
        bytes32 role = ADMIN_ROLE;
        bytes memory message = abi.encodeWithSignature(
            "AccessControlUnauthorizedAccount(address,bytes32)",
            user2,
            role
        );
        vm.expectRevert(message);
        stakingContract.slash(user1, 0.01 ether);
    }
    
    function test_SlashEmitsEvent() public {
        // First have user1 stake
        vm.prank(user1);
        stakingContract.stake{value: 0.05 ether}();
        
        // Prepare to check for event
        vm.prank(admin);
        vm.expectEmit(true, false, false, true);
        emit StakingContract.Slashed(user1, 0.01 ether);
        
        // Perform slash
        stakingContract.slash(user1, 0.01 ether);
    }
    
    function test_ReceiveFunction() public {
        // Send ETH directly to contract
        vm.prank(user1);
        (bool success,) = address(stakingContract).call{value: 0.05 ether}("");
        
        assertTrue(success);
        assertEq(stakingContract.stakes(user1), 0.05 ether);
    }
    
    function test_RevertWhen_ReceiveBelowMinimum() public {
        // Try to send less than minimum directly
        vm.prank(user1);
        
        // Use a more reliable way to test for reverts with low-level calls
        (bool success,) = address(stakingContract).call{value: 0.005 ether}("");
        assertFalse(success, "Transaction should have reverted");
    }
}