// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "forge-std/Test.sol";
import "../src/EngagementTracker.sol";
import "../src/SemaToken.sol";
import "../src/WalletFactory.sol";

contract EngagementTrackerTest is Test {
    EngagementTracker public tracker;
    SemaToken public token;
    WalletFactory public factory;
    WalletImplementation public implementation;
    
    address public admin = address(1);
    address public oracle = address(2);
    address public user = address(3);
    
    function setUp() public {
        // Deploy the WalletImplementation first
        vm.startPrank(admin);
        implementation = new WalletImplementation();
        
        // Deploy SemaToken as admin
        token = new SemaToken("Sema Token", "SEMA", admin);
        
        // Deploy WalletFactory with implementation
        factory = new WalletFactory(implementation);
        
        // Grant admin role to admin in the factory
        // This is the missing step - factory needs to have admin set up first
        factory.grantRole(factory.DEFAULT_ADMIN_ROLE(), admin);
        
        // Deploy EngagementTracker with token and factory addresses
        tracker = new EngagementTracker(address(token), address(factory));
        
        // Set up roles
        tracker.addOracle(oracle);
        token.grantRole(token.MINTER_ROLE(), address(tracker));
        factory.grantRole(factory.ADMIN_ROLE(), address(tracker));
        vm.stopPrank();
        
        // Set up platform metrics
        vm.prank(admin);
        tracker.updatePlatformMetrics("twitter", "like", 10);
        
        vm.prank(admin);
        tracker.updatePlatformMetrics("twitter", "retweet", 20);
        
        vm.prank(admin);
        tracker.updatePlatformMetrics("youtube", "view", 5);
        
        vm.prank(admin);
        tracker.updatePlatformMetrics("youtube", "comment", 15);
    }
    
    function testRecordEngagement() public {
        // Oracle records an engagement
        vm.prank(oracle);
        uint256 engagementId = tracker.recordEngagement(user, "twitter", "retweet");
        
        // Check the engagement was recorded correctly
        (uint256 id, address engagementUser, string memory platform, string memory action, uint256 score, bool validated) = tracker.engagements(engagementId);
        
        assertEq(id, engagementId);
        assertEq(engagementUser, user);
        assertEq(keccak256(abi.encodePacked(platform)), keccak256(abi.encodePacked("twitter")));
        assertEq(keccak256(abi.encodePacked(action)), keccak256(abi.encodePacked("retweet")));
        assertEq(score, 20);
        assertFalse(validated);
        
        // Check user score was updated
        assertEq(tracker.userScores(user), 20);
    }
    
    function testValidateEngagementAndMintTokens() public {
        // Record 5 retweets (20 points each = 100 points total)
        vm.startPrank(oracle);
        for (uint i = 0; i < 5; i++) {
            tracker.recordEngagement(user, "twitter", "retweet");
        }
        vm.stopPrank();
        
        // Check user score before validation
        assertEq(tracker.userScores(user), 100);
        
        // Initial token balance should be 0
        assertEq(token.balanceOf(user), 0);
        
        // Admin validates the first engagement
        vm.prank(admin);
        tracker.validateEngagement(1);
        
        // Check that a wallet was created
        assertTrue(tracker.walletExists(user));
        
        // Conversion rate is 100, so user should receive 1 token
        // Need to account for decimals (18)
        assertEq(token.balanceOf(user), 1 * 10**18);
        
        // User score should be reset to 0
        assertEq(tracker.userScores(user), 0);
    }
    
    function testCalculateScore() public view {
        // Test score calculation for different platforms and actions
        assertEq(tracker.calculateScore("twitter", "like"), 10);
        assertEq(tracker.calculateScore("twitter", "retweet"), 20);
        assertEq(tracker.calculateScore("youtube", "view"), 5);
        assertEq(tracker.calculateScore("youtube", "comment"), 15);
        assertEq(tracker.calculateScore("unknown", "action"), 0); // Non-existent should return 0
    }
}