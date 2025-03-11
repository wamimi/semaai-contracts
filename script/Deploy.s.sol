// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import {Script, console} from "forge-std/Script.sol";
import {WalletImplementation} from "../src/WalletImplementation.sol";
import {WalletFactory} from "../src/WalletFactory.sol";
import {SemaToken} from "../src/SemaToken.sol";
import {EngagementTracker} from "../src/EngagementTracker.sol";
import {StakingContract} from "../src/StakingContract.sol";

contract DeployScript is Script {
    WalletImplementation public implementation;
    WalletFactory public walletFactory;
    SemaToken public semaToken;
    EngagementTracker public tracker;
    StakingContract public stakingContract;

    // Configuration parameters
    string public constant TOKEN_NAME = "Sema Token";
    string public constant TOKEN_SYMBOL = "SEMA";

    function setUp() public {}

    function run() public {
        // Get the deployer address from the private key
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployerAddress = vm.addr(deployerPrivateKey);
        
        console.log("Deploying contracts with address:", deployerAddress);
        
        vm.startBroadcast(deployerPrivateKey);

        // 1. Deploy WalletImplementation
        implementation = new WalletImplementation();
        console.log("WalletImplementation deployed at:", address(implementation));

        // 2. Deploy SemaToken
        semaToken = new SemaToken(TOKEN_NAME, TOKEN_SYMBOL, deployerAddress);
        console.log("SemaToken deployed at:", address(semaToken));

        // 3. Deploy WalletFactory with implementation
        walletFactory = new WalletFactory(implementation);
        console.log("WalletFactory deployed at:", address(walletFactory));

        // 4. Deploy EngagementTracker with token and factory addresses
        tracker = new EngagementTracker(address(semaToken), address(walletFactory));
        console.log("EngagementTracker deployed at:", address(tracker));

        // 5. Deploy StakingContract
        stakingContract = new StakingContract();
        console.log("StakingContract deployed at:", address(stakingContract));

        // 6. Set up roles and permissions
        
        // Grant MINTER_ROLE to EngagementTracker in SemaToken
        semaToken.grantRole(semaToken.MINTER_ROLE(), address(tracker));
        console.log("Granted MINTER_ROLE to EngagementTracker in SemaToken");
        
        // Grant ADMIN_ROLE to EngagementTracker in WalletFactory
        walletFactory.grantRole(walletFactory.ADMIN_ROLE(), address(tracker));
        console.log("Granted ADMIN_ROLE to EngagementTracker in WalletFactory");

        vm.stopBroadcast();
        
        console.log("Deployment completed successfully!");
    }
}
