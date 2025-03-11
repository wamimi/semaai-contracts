// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./SemaToken.sol";
import "./WalletFactory.sol";

/**
 * @title EngagementTracker
 * @notice Records and validates user engagements, calculates token rewards, and interacts with
 *         the SemaToken and WalletFactory contracts. Uses an OpenZeppelin ReentrancyGuard.
 */
contract EngagementTracker is AccessControl, ReentrancyGuard {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant ORACLE_ROLE = keccak256("ORACLE_ROLE");

    // References to external contracts.
    SemaToken public semaToken;
    WalletFactory public walletFactory;

    // Engagement identifier counter starting at 1.
    uint256 private nextEngagementId = 1;

    // Conversion rate: for example, 100 engagement points equal 1 SemaToken.
    uint256 public constant CONVERSION_RATE = 100;

    struct Engagement {
        uint256 id;
        address user;
        string platform;
        string action;
        uint256 score;
        bool validated;
    }

    // Mapping of engagement ID to details.
    mapping(uint256 => Engagement) public engagements;
    // Mapping of user addresses to accumulated engagement scores.
    mapping(address => uint256) public userScores;
    // Mapping from platform to action to engagement weight.
    mapping(string => mapping(string => uint256)) public platformMetrics;

    event EngagementRecorded(uint256 indexed engagementId, address indexed user, string platform, string action, uint256 score);
    event TokensMinted(address indexed user, uint256 amount);

    /**
     * @notice Constructor sets the addresses of SemaToken and WalletFactory and assigns the admin role.
     * @param _semaToken Address of the deployed SemaToken contract.
     * @param _walletFactory Address of the deployed WalletFactory contract.
     */
    constructor(address _semaToken, address _walletFactory) {
        semaToken = SemaToken(_semaToken);
        walletFactory = WalletFactory(_walletFactory);
        _grantRole(ADMIN_ROLE, msg.sender);
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /**
     * @notice Records a new engagement. Only addresses with ORACLE_ROLE can call this.
     * @param user The address performing the engagement.
     * @param platform The platform identifier.
     * @param action The specific action performed.
     * @return The newly created engagement ID.
     */
    function recordEngagement(address user, string memory platform, string memory action) external onlyRole(ORACLE_ROLE) returns (uint256) {
        uint256 currentId = nextEngagementId;
        nextEngagementId++;

        uint256 score = calculateScore(platform, action);

        engagements[currentId] = Engagement({
            id: currentId,
            user: user,
            platform: platform,
            action: action,
            score: score,
            validated: false
        });

        userScores[user] += score;
        emit EngagementRecorded(currentId, user, platform, action, score);
        return currentId;
    }

    /**
     * @notice Calculates the score for a given engagement based on stored metrics.
     * @param platform The platform identifier.
     * @param action The engagement action.
     * @return The score associated with the platform and action.
     */
    function calculateScore(string memory platform, string memory action) public view returns (uint256) {
        return platformMetrics[platform][action];
    }

    /**
     * @notice Validates an engagement and, if the user has accumulated enough score,
     *         mints tokens as a reward. Only ADMIN_ROLE can call.
     * @param engagementId The engagement's unique identifier.
     */
    function validateEngagement(uint256 engagementId) external nonReentrant onlyRole(ADMIN_ROLE) {
        Engagement storage engagement = engagements[engagementId];
        require(engagement.id != 0, "Engagement does not exist");
        require(!engagement.validated, "Engagement already validated");

        engagement.validated = true;

        uint256 totalScore = userScores[engagement.user];
        uint256 tokensDue = totalScore / CONVERSION_RATE;

        if (tokensDue > 0) {
            // Ensure the user has a wallet; if not, create a parent wallet.
            if (!walletExists(engagement.user)) {
                walletFactory.createParentWallet(engagement.user);
            }
            // Mint tokens to the user. Note: EngagementTracker must have MINTER_ROLE in SemaToken.
            // Multiply by decimals (typically 18) for correct base unit conversion.
            semaToken.mint(engagement.user, tokensDue * (10 ** uint256(semaToken.decimals())));
            emit TokensMinted(engagement.user, tokensDue);
            // Optionally, reset the user's score after minting rewards.
            userScores[engagement.user] = 0;
        }
    }

    /**
     * @notice Checks whether the user already has a parent wallet.
     * @param user The user’s address.
     * @return True if a wallet exists, false otherwise.
     */
    function walletExists(address user) public view returns (bool) {
        return (walletFactory.parentWalletOfOwner(user) != 0);
    }

    /**
     * @notice Update the weight for a given action on a platform.
     * @param platform The platform identifier.
     * @param action The action type.
     * @param weight The new weight (score) to assign.
     */
    function updatePlatformMetrics(string memory platform, string memory action, uint256 weight) external onlyRole(ADMIN_ROLE) {
        platformMetrics[platform][action] = weight;
    }

    /**
     * @notice Grant ORACLE_ROLE to an address.
     * @param account The address to be granted the ORACLE_ROLE.
     */
    function addOracle(address account) external onlyRole(ADMIN_ROLE) {
        grantRole(ORACLE_ROLE, account);
    }

    /**
     * @notice Revoke ORACLE_ROLE from an address.
     * @param account The address to have ORACLE_ROLE revoked.
     */
    function removeOracle(address account) external onlyRole(ADMIN_ROLE) {
        revokeRole(ORACLE_ROLE, account);
    }
}