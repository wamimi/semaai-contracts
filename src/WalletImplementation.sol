// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;
/**
 * @title WalletImplementation
 * @notice Minimal wallet contract used as the implementation for clones.
 *         It includes an initialize function that can only be called once.
 */

contract WalletImplementation {
    address public owner;
    uint256 public walletId;
    string public role;
    bool public initialized;

    /**
     * @notice Initialize the proxy wallet.
     * @param _owner The designated owner.
     * @param _walletId Unique wallet ID.
     * @param _role The role assigned (“parent” or “child”).
     */
    function initialize(address _owner, uint256 _walletId, string memory _role) external {
        require(!initialized, "Already initialized");
        owner = _owner;
        walletId = _walletId;
        role = _role;
        initialized = true;
    }
}