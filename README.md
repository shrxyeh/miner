# HealthInsureChain

**Health Insurance Claim Verification with Blockchain Technology**

HealthInsureChain is a comprehensive blockchain-based system that automates insurance approvals and claim validation using Ethereum private chain, smart contracts, and a Rust-based miner for block confirmation simulation.

##  Architecture

The system consists of four main components:

1. **Ethereum Private Chain** - Stores policy hashes and processes transactions
2. **Solidity Smart Contract** - Handles policy registration and claim verification
3. **Rust Miner** - Simulates block confirmation and monitors policy blocks
4. **Hyperledger Fabric** - Hospital-Insurance inter-org data sharing and cross-network integration

##  Features

- **Policy Registration**: Register insurance policies with hashed values on blockchain
- **Automated Claim Verification**: Smart contract automatically verifies claim conditions
- **Block Confirmation**: Rust miner monitors and confirms policy blocks
- **Cross-Network Integration**: Seamless data sharing between Ethereum and Fabric networks
- **Hospital-Insurance Data Sharing**: Secure inter-organization data exchange via Fabric
- **REST API**: Complete API for interacting with both blockchain networks
- **Comprehensive Validation**: Checks policy validity, claim amounts, and time constraints
- **Event Logging**: Complete audit trail of all transactions and events

##  Requirements

- Node.js (v16 or higher)
- Rust (latest stable version)
- Foundry (Forge, Anvil, Cast)
- Hardhat
- Docker and Docker Compose
- Hyperledger Fabric Tools (cryptogen, configtxgen)
- Git

##  Installation

### 1. Clone the Repository

```bash
git clone <repository-url>
cd miner
git checkout healthinsurechain-implementation
```

### 2. Install Dependencies

```bash
# Install Node.js dependencies
npm install

# Install Rust dependencies
cd rust-miner
cargo build
cd ..
```

### 3. Install Foundry (if not already installed)

```bash
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

### 4. Install Hyperledger Fabric Tools

```bash
# Install Fabric tools
curl -sSL https://bit.ly/2ysbOFE | bash -s -- 2.5.0 1.5.0

# Add to PATH
export PATH=$PATH:$HOME/fabric-samples/bin
```

##  Quick Start

### 1. Start Local Ethereum Node

```bash
# Using Anvil (Foundry)
anvil

# Or using Hardhat
npm run node
```

### 2. Deploy Smart Contracts

```bash
# Using Foundry
npm run forge:deploy

# Or using Hardhat
npm run deploy
```

### 3. Run Example Workflow

```bash
# Using Foundry
npm run forge:workflow

# Or using Hardhat
npm run interact
```

### 4. Start Rust Miner

```bash
# Start miner with default settings
npm run miner

# Start miner with custom settings
npm run miner:dev
```

### 5. Setup and Start Fabric Network

```bash
# Setup Fabric network (first time only)
npm run fabric:setup

# Start Fabric network
npm run fabric:start

# Start Fabric API server
npm run fabric:api
```

### 6. Run Integration Demo

```bash
# Run the complete integration demo
node js/fabric-integration-demo.js
```

##  Project Structure

```
miner/
├── src/                          # Solidity smart contracts
│   ├── PolicyClaim.sol          # Main contract for policy and claim management
│   ├── HealthInsurance.sol      # Legacy contract (for reference)
│   ├── HealthToken.sol          # ERC20 token contract
│   └── PolicyStorage.sol        # Legacy policy storage contract
├── script/                       # Foundry deployment scripts
│   ├── DeployPolicyClaim.s.sol  # Contract deployment script
│   └── PolicyWorkflow.s.sol     # Example workflow script
├── js/                          # Node.js interaction scripts
│   ├── deploy.js                # Hardhat deployment script
│   ├── interact.js              # Interaction demonstration script
│   └── fabric-integration-demo.js # Fabric integration demo
├── rust-miner/                  # Rust miner implementation
│   ├── src/
│   │   └── main.rs              # Main miner logic
│   └── Cargo.toml               # Rust dependencies
├── fabric-network/              # Hyperledger Fabric network
│   ├── docker-compose.yaml      # Fabric network configuration
│   ├── configtx.yaml            # Channel configuration
│   ├── crypto-config.yaml       # Crypto material configuration
│   ├── setup-fabric.sh          # Fabric network setup script
│   └── scripts/                 # Fabric utility scripts
├── fabric-integration/          # Ethereum-Fabric integration
│   └── ethereum-fabric-bridge.js # Cross-network bridge
├── fabric-api/                  # REST API for Fabric
│   ├── server.js                # Express API server
│   ├── package.json             # API dependencies
│   └── connection-profile.json  # Fabric connection profile
├── deployments/                 # Deployment information
├── foundry.toml                 # Foundry configuration
├── hardhat.config.js            # Hardhat configuration
└── package.json                 # Node.js dependencies and scripts
```

##  Smart Contract Details

### PolicyClaim.sol

The main smart contract that handles:

- **Policy Registration**: Register insurance policies with comprehensive validation
- **Claim Submission**: Submit claims against registered policies
- **Automated Verification**: Automatically verify claim conditions
- **Policy Management**: Activate/deactivate policies


##  Rust Miner

The Rust miner (`rust-miner/`) provides:

- **Block Monitoring**: Continuously monitors the Ethereum chain for new blocks
- **Policy Detection**: Identifies blocks containing policy-related transactions
- **Confirmation Simulation**: Simulates block confirmation process
- **Event Logging**: Comprehensive logging of all miner activities

### Miner Features

- Configurable RPC URL and polling interval
- Block confirmation threshold settings
- Policy transaction detection
- Post-confirmation processing simulation
- Comprehensive error handling and logging

### Usage

```bash
# Basic usage
cargo run

# With custom parameters
cargo run -- --rpc-url http://localhost:8545 --poll-interval 5 --confirmation-threshold 12
```

##  Hyperledger Fabric Integration

The Fabric component (`fabric-network/`, `fabric-integration/`, `fabric-api/`) provides:

- **Hospital-Insurance Data Sharing**: Secure inter-organization data exchange
- **Cross-Network Integration**: Seamless synchronization between Ethereum and Fabric
- **Patient Record Management**: Comprehensive patient data storage and retrieval
- **Claim Processing**: Automated claim request handling and status updates
- **REST API**: Complete API for interacting with Fabric network

### Fabric Network Architecture

- **Orderer**: Single orderer for transaction ordering
- **Hospital Organization**: Peer for hospital data and operations
- **Insurance Organization**: Peer for insurance data and operations
- **Shared Channel**: Common channel for inter-organization communication

### Chaincode Features

The HealthInsureChain chaincode (`fabric-network/chaincode/healthinsurechain.go`) provides:

- **Patient Record Management**: Create, read, and query patient records
- **Claim Request Processing**: Submit, update, and track claim requests
- **Policy Verification**: Verify policy data from Ethereum blockchain
- **Cross-Organization Queries**: Query data across Hospital and Insurance organizations
- **Audit Trail**: Complete transaction history and event logging

### Integration Bridge

The Ethereum-Fabric Bridge (`fabric-integration/ethereum-fabric-bridge.js`) provides:

- **Policy Synchronization**: Sync policy data from Ethereum to Fabric
- **Claim Processing**: Create claims in both networks simultaneously
- **Status Updates**: Keep claim status synchronized across networks
- **Event Monitoring**: Monitor Ethereum events and update Fabric accordingly
- **Data Validation**: Ensure data consistency between networks

### REST API

The Fabric API (`fabric-api/server.js`) provides endpoints for:

- **Patient Records**: Create and query patient records
- **Claim Management**: Submit, process, and track claims
- **Policy Operations**: Sync and verify policies
- **Organization Queries**: Get data by hospital or insurance company
- **Health Monitoring**: System health and status checks

### Usage

```bash
# Setup Fabric network (first time)
npm run fabric:setup

# Start Fabric network
npm run fabric:start

# Start Fabric API
npm run fabric:api

# Run integration demo
node js/fabric-integration-demo.js
```

##  Example Workflow

### Complete Cross-Network Workflow

1. **Policy Registration (Ethereum)**
   - Insurer registers a policy for a policy holder
   - Policy details are stored on-chain with hash verification
   - Policy becomes active and available for claims

2. **Policy Synchronization (Ethereum → Fabric)**
   - Policy data is automatically synced to Fabric network
   - Hospital and Insurance organizations can access policy information
   - Cross-network verification ensures data consistency

3. **Patient Record Creation (Fabric)**
   - Hospital creates patient record in Fabric network
   - Record includes diagnosis, treatment, and cost information
   - Data is shared with Insurance organization for claim processing

4. **Claim Submission (Cross-Network)**
   - Hospital submits claim request through Fabric API
   - Claim is created in both Ethereum and Fabric networks
   - Cross-network transaction IDs are linked for tracking

5. **Automated Verification (Ethereum)**
   - Smart contract automatically verifies claim conditions:
     - Policy is valid and active
     - Claim amount ≤ insured amount
     - Claim amount ≤ maximum allowed ratio (80%)
     - Policy is within valid time period

6. **Status Synchronization (Ethereum → Fabric)**
   - Claim status is updated in Fabric network
   - Hospital and Insurance organizations receive real-time updates
   - Cross-network event monitoring ensures consistency

7. **Block Confirmation (Ethereum)**
   - Rust miner monitors for policy blocks
   - Confirms blocks containing policy transactions
   - Logs confirmation details and triggers post-processing

8. **Result Processing (Cross-Network)**
   - Approved claims are marked as approved in both networks
   - Rejected claims include rejection reasons
   - All events are logged for audit purposes across networks
   - Hospital and Insurance organizations can query final results

##  Testing

### Run Tests

```bash
# Foundry tests
npm run forge:test

# Compile contracts
npm run forge:build
```

### Example Test Scenarios

1. **Valid Policy Registration**: Register policy with valid parameters
2. **Invalid Policy Registration**: Attempt to register with invalid parameters
3. **Valid Claim Submission**: Submit claim within policy limits
4. **Invalid Claim Submission**: Submit claim exceeding policy limits
5. **Policy Expiration**: Test claims after policy expiration
6. **Block Confirmation**: Test miner block confirmation process

##  Security Features

- **Access Control**: Only insurer can register policies
- **Input Validation**: Comprehensive validation of all inputs
- **Amount Limits**: Maximum claim ratio enforcement
- **Time Validation**: Policy validity period checks
- **Event Logging**: Complete audit trail

##  Performance Considerations

- **Gas Optimization**: Efficient contract design for minimal gas usage
- **Batch Processing**: Support for multiple operations in single transaction
- **Event Filtering**: Efficient event filtering for miner operations
- **Error Handling**: Robust error handling and recovery

##  Deployment

### Local Development

1. Start local Ethereum node (Anvil or Hardhat)
2. Deploy contracts using provided scripts
3. Start Rust miner
4. Run example workflows

### Production Deployment

1. Configure production RPC URL
2. Update private keys and addresses
3. Deploy to target network
4. Configure miner for production environment

##  Available Scripts

### Ethereum Operations
- `npm run deploy` - Deploy smart contracts using Hardhat
- `npm run interact` - Run interaction demo
- `npm run forge:deploy` - Deploy contracts using Foundry
- `npm run forge:workflow` - Run complete workflow demo
- `npm run miner` - Start Rust miner
- `npm run miner:dev` - Start Rust miner with custom settings

### Fabric Operations
- `npm run fabric:setup` - Setup Fabric network (first time)
- `npm run fabric:start` - Start Fabric network
- `npm run fabric:stop` - Stop Fabric network
- `npm run fabric:clean` - Clean Fabric network and data
- `npm run fabric:api` - Start Fabric API server
- `npm run fabric:api:dev` - Start Fabric API server in development mode

### Integration
- `node js/fabric-integration-demo.js` - Run complete integration demo

##  Future Enhancements

- **Multi-token Support**: Support for different ERC20 tokens
- **Advanced Analytics**: Detailed analytics and reporting across both networks
- **Enhanced Integration**: More sophisticated cross-network synchronization
- **Mobile Support**: Mobile app for policy holders and hospital staff
- **Advanced Mining**: More sophisticated mining algorithms with Fabric integration
- **Multi-chain Support**: Support for additional blockchain networks
- **Privacy Features**: Enhanced privacy controls for sensitive medical data
- **AI Integration**: Machine learning for claim fraud detection
- **Real-time Notifications**: WebSocket support for real-time updates

---

**HealthInsureChain** - Revolutionizing health insurance with blockchain technology! 🏥⛓️