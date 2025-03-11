// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "forge-std/Test.sol";
import "../src/SemaToken.sol";

contract SemaTokenSimpleTest is Test {
    SemaToken public token;
    address public admin = address(1);
    address public user = address(2);
    
    function setUp() public {
        // Deploy the token contract
        token = new SemaToken("Sema Token", "SEMA", admin);
    }
    
    function testBasicFunctionality() public {
        // Check initial state
        assertEq(token.name(), "Sema Token");
        assertEq(token.symbol(), "SEMA");
        assertEq(token.totalSupply(), 8_000_000 * 10**18);
        assertEq(token.balanceOf(admin), 8_000_000 * 10**18);
        
        // Test minting as admin
        vm.prank(admin);
        token.mint(user, 1000 * 10**18);
        assertEq(token.balanceOf(user), 1000 * 10**18);
        
        // Test burning
        vm.prank(user);
        token.burn(500 * 10**18);
        assertEq(token.balanceOf(user), 500 * 10**18);
    }
}