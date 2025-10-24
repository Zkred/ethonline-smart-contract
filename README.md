# ETHOnline 2025 - Decentralized Identity Registry

A comprehensive smart contract system for managing AI agent registrations with Decentralized Identifiers (DIDs) and meta-transaction support.

## Project Overview

This project implements a decentralized identity registry system that allows AI agents to register with unique DIDs, manage service endpoints, and interact through gas-less meta-transactions. The system consists of two main contracts:

### Contract Architecture

#### 1. **DIDValidator.sol**

A comprehensive DID validation contract that:

- Validates Decentralized Identifiers (DIDs) against Ethereum addresses
- Implements Base58 decoding for DID processing
- Provides detailed validation results for debugging
- Extracts Ethereum addresses from DID strings
- Ensures DID format compliance and uniqueness

**Key Features:**

- Base58 encoding/decoding implementation
- Ethereum address extraction from DIDs
- Comprehensive validation with detailed error reporting
- Gas-efficient validation algorithms

#### 2. **IdentityRegistry.sol (AgentRegistry)**

The main registry contract that:

- Manages AI agent registrations with unique DIDs
- Implements EIP-712 signature-based meta-transactions
- Handles native token registration fees
- Provides agent lookup by address and ID
- Manages service endpoint updates

**Key Features:**

- Native token registration fee (configurable)
- EIP-712 signature support for gas-less onboarding
- Service endpoint management
- Agent lookup and discovery
- Nonce-based replay protection

## Quick Start

### Prerequisites

- Node.js 22.10.0 or later (LTS recommended)
- npm or yarn package manager
- Git

### Installation

1. **Clone the repository:**

```bash
git clone git@github.com:Zkred/ethonline-smart-contract.git
cd ethonline-smart-contract
```

2. **Install dependencies:**

```bash
npm install
```

3. **Install OpenZeppelin contracts:**

```bash
npm install @openzeppelin/contracts
```

## 🔧 Environment Setup

### Using Hardhat Keystore (Recommended)

The project uses Hardhat's keystore plugin for secure key management. Set up your environment variables:

#### For Hedera Network:

```bash
# Set Hedera RPC URL
npx hardhat keystore set HEDERA_RPC_URL

# Set Hedera private key
npx hardhat keystore set HEDERA_PRIVATE_KEY
```

#### For Sepolia Testnet:

```bash
# Set Sepolia RPC URL
npx hardhat keystore set SEPOLIA_RPC_URL

# Set Sepolia private key
npx hardhat keystore set SEPOLIA_PRIVATE_KEY
```

### Alternative: Environment Variables

You can also set environment variables directly:

```bash
export HEDERA_RPC_URL="https://testnet.hashio.io/api"
export HEDERA_PRIVATE_KEY="your-private-key-here"
export SEPOLIA_RPC_URL="https://sepolia.infura.io/v3/your-project-id"
export SEPOLIA_PRIVATE_KEY="your-private-key-here"
```

## 🚀 Deployment

### Local Development

Deploy to Hardhat's local network:

```bash
npx hardhat ignition deploy ./ignition/modules/IdentityRegistry.ts
```

### Hedera Network

Deploy to Hedera testnet:

```bash
npx hardhat ignition deploy ./ignition/modules/IdentityRegistry.ts --network hedera
```

### Sepolia Testnet

Deploy to Sepolia testnet:

```bash
npx hardhat ignition deploy ./ignition/modules/IdentityRegistry.ts --network sepolia
```

## 📝 Deployment Details

The deployment script (`ignition/modules/IdentityRegistry.ts`) automatically:

1. **Deploys DIDValidator first** - Required for DID validation
2. **Deploys IdentityRegistry** - With DIDValidator address and decimal=6
3. **Returns both contract addresses** - For further interaction

### Deployment Output Example:

```
IdentityRegistryModule#DIDValidator - 0x5FbDB2315678afecb367f032d93F642f64180aa3
IdentityRegistryModule#AgentRegistry - 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512
```

## 🧪 Testing

Run the test suite:

```bash
# Run all tests
npx hardhat test

# Run only Solidity tests
npx hardhat test solidity

# Run only Mocha tests
npx hardhat test mocha
```

## 📚 Contract Usage

### Registering an Agent

#### Direct Registration (with gas):

```solidity
// Call registerAgent with ETH for registration fee
agentRegistry.registerAgent(
    "did:hedera:testnet:0.0.1234567890_abcdef1234567890",
    "AI Agent Description",
    "https://api.agent.com/endpoint"
);
```

#### Meta-Transaction Registration (gas-less):

```solidity
// Create EIP-712 signature and call registerAgentWithSig
agentRegistry.registerAgentWithSig(
    forwardRequest,
    signature
);
```

### Querying Agents

```solidity
// Get agent by address
AgentInfo memory agent = agentRegistry.getAgentByAddress(agentAddress);

// Get agent by ID
AgentInfo memory agent = agentRegistry.getAgentById(agentId);

// Get agent's DID
string memory did = agentRegistry.getAgentDID(agentAddress);

// Get service endpoint
string memory endpoint = agentRegistry.getAgentServiceEndpoint(agentAddress);

// Get agent by service endpoint
AgentInfo memory agent = agentRegistry.getAgentByServiceEndpoint("https://api.agent.com/endpoint");
```

## 🔍 DID Validation

The DIDValidator contract provides comprehensive DID validation:

```solidity
// Validate DID against address
bool isValid = didValidator.validateDID(didString, expectedAddress);

// Get detailed validation results
ValidationResult memory result = didValidator.getValidationDetails(didString, expectedAddress);

// Extract address from DID
(address extractedAddress, bool success) = didValidator.extractAddressFromDID(didString);
```

## 🏗️ Project Structure

```
ethonline-smart-contract/
├── contracts/
│   ├── DIDValidator.sol              # DID validation logic
│   ├── IdentityRegistry.sol          # Main registry contract
│   └── Interface/
│       ├── IDIDValidator.sol         # DID validator interface
│       └── IIdentityRegistry.sol     # Registry interface
├── ignition/
│   └── modules/
│       ├── Counter.ts               # Example deployment
│       └── IdentityRegistry.ts   # Registry deployment script
├── scripts/
│   └── send-op-tx.ts               # Meta-transaction utilities
├── test/
│   └── Counter.ts                   # Test examples
├── hardhat.config.ts               # Hardhat configuration
└── package.json                    # Dependencies
```

## 🔧 Configuration

### Network Configuration

The project supports multiple networks:

- **hardhat**: Local development network
- **hardhatMainnet**: Simulated mainnet
- **hardhatOp**: Simulated Optimism
- **sepolia**: Sepolia testnet
- **hedera**: Hedera testnet

### Solidity Configuration

- **Version**: 0.8.28
- **Optimizer**: Enabled for production (200 runs)
- **OpenZeppelin**: v5.4.0

## 🛡️ Security Features

- **EIP-712 Signatures**: Secure meta-transaction support
- **Nonce Protection**: Replay attack prevention
- **DID Validation**: Comprehensive DID format validation
- **Access Control**: Proper permission management
- **Gas Optimization**: Efficient contract design

## 📖 API Reference

### DIDValidator Functions

- `validateDID(string, address) → bool`: Validate DID against address
- `getValidationDetails(string, address) → ValidationResult`: Get detailed validation info
- `extractAddressFromDID(string) → (address, bool)`: Extract address from DID

### IdentityRegistry Functions

- `registerAgent(string, string, string)`: Direct agent registration
- `registerAgentWithSig(ForwardRequest, bytes)`: Meta-transaction registration
- `updateServiceEndpoint(string)`: Update agent's service endpoint
- `getAgentByAddress(address) → AgentInfo`: Get agent by address
- `getAgentById(uint256) → AgentInfo`: Get agent by ID
- `getAgentDID(address) → string`: Get agent's DID
- `getAgentServiceEndpoint(address) → string`: Get service endpoint
- `getAgentByServiceEndpoint(string) → AgentInfo`: Get agent by service endpoint

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.
