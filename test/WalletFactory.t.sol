// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "forge-std/Test.sol";
import "../src/WalletFactory.sol";

contract WalletFactoryTest is Test {
    WalletFactory public factory;
    WalletImplementation public implementation;
    
    address public admin = address(1);
    address public minter = address(2);
    address public user1 = address(3);
    address public user2 = address(4);
    
    function setUp() public {
        // Deploy the implementation contract first
        implementation = new WalletImplementation();
        
        // Deploy the factory with the implementation address
        vm.startPrank(address(999));
        factory = new WalletFactory(implementation);
        
        // Grant DEFAULT_ADMIN_ROLE to admin (this was missing)
        factory.grantRole(factory.DEFAULT_ADMIN_ROLE(), admin);
        
        // Grant ADMIN_ROLE to admin
        factory.grantRole(factory.ADMIN_ROLE(), admin);
        vm.stopPrank();
        
        // Now admin can add minters
        vm.prank(admin);
        factory.addMinter(minter);
    }
    
    function testCreateParentWallet() public {
        // Admin creates a parent wallet for user1
        vm.prank(admin);
        uint256 parentId = factory.createParentWallet(user1);
        
        // Verify the wallet was created correctly
        (uint256 id, address walletAddress, uint256 parentIdStored, string memory role, address owner) = factory.wallets(parentId);
        
        assertEq(id, parentId);
        assertEq(owner, user1);
        assertEq(parentIdStored, 0);
        assertEq(keccak256(abi.encodePacked(role)), keccak256(abi.encodePacked("parent")));
        assertEq(factory.parentWalletOfOwner(user1), parentId);
    }
    
    function testCreateChildWallet() public {
        // First create a parent wallet
        vm.prank(admin);
        uint256 parentId = factory.createParentWallet(user1);
        
        // Create a child wallet linked to the parent
        vm.prank(minter);
        uint256 childId = factory.createChildWallet(parentId, user2);
        
        // Verify the child wallet
        (uint256 id, address walletAddress, uint256 parentIdStored, string memory role, address owner) = factory.wallets(childId);
        
        assertEq(id, childId);
        assertEq(owner, user2);
        assertEq(parentIdStored, parentId);
        assertEq(keccak256(abi.encodePacked(role)), keccak256(abi.encodePacked("child")));
        
        // Check parent-child mapping
        uint256[] memory childWallets = factory.getChildWallets(parentId);
        assertEq(childWallets.length, 1);
        assertEq(childWallets[0], childId);
    }
    
    function testRoleManagement() public {
        // Test adding a new minter
        vm.prank(admin);
        factory.addMinter(user1);
        assertTrue(factory.hasRole(factory.MINTER_ROLE(), user1));
        
        // Test removing a minter
        vm.prank(admin);
        factory.removeMinter(user1);
        assertFalse(factory.hasRole(factory.MINTER_ROLE(), user1));
    }
}