# Sema Smart Contracts
SemaAI is a cross-platform engagement reward system that tracks and validates social media interactions across Telegram, Discord, and Twitter, then assigns engagement scores and rewards users with tokens. This repository contains the smart contracts that power the blockchain component of the SemaAI platform.

This repository contains the smart contracts for the Sema platform, which includes:

#### 1. SemaToken(0xd0a824fbB75C92224bDcae836A877A25db43ae96)

An ERC-20 token with role-based minting and burning capabilities:
Total Supply: `8,000,000` SEMA tokens
Decimals: 18
Features:
Role-based access control (ADMIN_ROLE, MINTER_ROLE)
Minting functionality for authorized entities
Burning functionality for token holders

#### 2. WalletImplementation (0xcf93951352635ee4bdbc453a2eed63eb4722a762)

A minimal contract used as the implementation for proxy wallets:
Features:
Stores wallet owner, ID, and role
Initialization function that can only be called once
Used as the base for cloned wallets

#### 3. WalletFactory(0x56450BFE0fA8A3cDB71CF00144E0297CBAe53998)

Creates and manages user wallets using a minimal proxy pattern:

### Features:
Creates parent wallets for content creators

Creates child wallets linked to parent wallets

Uses CREATE2 for deterministic wallet generation

Maintains relationships between parent and child wallets

Role-based access control for wallet creation

#### 4.EngagementTracker(0x5E8Fd84e35dA89f22c31CA1C77E7E239353409F8)

Records and validates user engagements, calculates rewards:

### Features:
Records engagement data (user, platform, action)

Calculates scores based on platform and action type

Validates engagements and issues token rewards

Creates wallets for users via WalletFactory

Configurable platform metrics for different engagement types

#### 5. StakingContract
Implements staking and slashing mechanisms for anti-Sybil protection:

### Features:
Users stake ETH to participate in the platform

Minimum stake requirement (0.01 ETH)

Withdrawal functionality for legitimate users

Slashing mechanism for penalizing malicious behavior

Role-based access control for admin functions

#### Contract Interaction Flow
#### User Onboarding:
User stakes ETH via StakingContract to participate in the protocol

#### Engagement Recording:
Social media interactions are tracked across platforms
EngagementTracker receives validated data and records it on-chain

#### Wallet Creation:
For new users, WalletFactory creates a parent wallet
Child wallets can be created for specific engagement types eg retweet, likes, shares, replies etc

#### Reward Distribution:
EngagementTracker calculates rewards based on engagement scores
SemaToken mints tokens to user wallets

#### Anti-Sybil Measures:
StakingContract enforces minimum stake requirements
Suspicious behavior can result in slashing of staked ETH



## Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation)
- An Ethereum RPC URL (Mainnet, Testnet, or local node)
- A wallet private key for deployment

## Setup

1. Clone the repository:
```shell
git clone <https://github.com/wamimi/semaai-contracts>
cd semaai-contracts
```

2. Install dependencies:
```shell
forge install
```

3. Build the contracts:
```shell
forge build
```

## Testing

Run the test suite to ensure everything is working correctly:

```shell
forge test
```

For more verbose output:

```shell
forge test -vvv
```

## Deployment

The deployment script will deploy all contracts in the correct order and set up the necessary permissions.

1. Create a `.env` file with your deployment configuration:
```
PRIVATE_KEY=your_private_key_here
RPC_URL=your_rpc_url_here
ETHERSCAN_API_KEY=your_etherscan_api_key_here  # Optional, for verification
```

2. Source the environment variables:
```shell
source .env
```

3. Deploy the contracts:
```shell
forge script script/Deploy.s.sol:DeployScript --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast
```

4. (Optional) Verify the contracts on Etherscan:
```shell
forge script script/Deploy.s.sol:DeployScript --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast --verify --etherscan-api-key $ETHERSCAN_API_KEY
```

## Contract Interactions

After deployment, you'll need to:

1. Add oracles to the EngagementTracker:
```shell
cast send --private-key $PRIVATE_KEY <TRACKER_ADDRESS> "addOracle(address)" <ORACLE_ADDRESS>
```

2. Set up platform metrics in the EngagementTracker:
```shell
cast send --private-key $PRIVATE_KEY <TRACKER_ADDRESS> "updatePlatformMetrics(string,string,uint256)" "twitter" "like" 10
cast send --private-key $PRIVATE_KEY <TRACKER_ADDRESS> "updatePlatformMetrics(string,string,uint256)" "twitter" "retweet" 20
cast send --private-key $PRIVATE_KEY <TRACKER_ADDRESS> "updatePlatformMetrics(string,string,uint256)" "youtube" "view" 5
cast send --private-key $PRIVATE_KEY <TRACKER_ADDRESS> "updatePlatformMetrics(string,string,uint256)" "youtube" "comment" 15
```

### Security Considerations
*Role-Based Access Control*: All contracts use OpenZeppelin's AccessControl for permission management

*Reentrancy Protection*: StakingContract uses ReentrancyGuard to prevent reentrancy attacks

*Minimal Proxy Pattern*: WalletFactory uses Clones library to minimize gas costs and attack surface

*Validation Checks*: All contracts include proper validation to ensure data integrity


## License

MIT
