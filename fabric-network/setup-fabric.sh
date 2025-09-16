#!/bin/bash

# HealthInsureChain Fabric Network Setup Script

set -e

echo "Setting up HealthInsureChain Fabric Network..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if required tools are installed
check_dependencies() {
    print_status "Checking dependencies..."
    
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed. Please install Docker first."
        exit 1
    fi
    
    if ! command -v docker-compose &> /dev/null; then
        print_error "Docker Compose is not installed. Please install Docker Compose first."
        exit 1
    fi
    
    if ! command -v cryptogen &> /dev/null; then
        print_error "cryptogen is not installed. Please install Hyperledger Fabric tools first."
        print_warning "You can install Fabric tools by running:"
        print_warning "curl -sSL https://bit.ly/2ysbOFE | bash -s -- 2.5.0 1.5.0"
        exit 1
    fi
    
    if ! command -v configtxgen &> /dev/null; then
        print_error "configtxgen is not installed. Please install Hyperledger Fabric tools first."
        exit 1
    fi
    
    print_status "All dependencies are installed."
}

# Clean up previous setup
cleanup() {
    print_status "Cleaning up previous setup..."
    
    # Stop and remove containers
    docker-compose down -v 2>/dev/null || true
    
    # Remove crypto material
    rm -rf crypto-config 2>/dev/null || true
    
    # Remove channel artifacts
    rm -rf channel-artifacts 2>/dev/null || true
    
    # Remove chaincode containers
    docker rm $(docker ps -aq --filter "name=dev-peer") 2>/dev/null || true
    
    # Remove chaincode images
    docker rmi $(docker images "dev-peer*" -q) 2>/dev/null || true
    
    print_status "Cleanup completed."
}

# Generate crypto material
generate_crypto() {
    print_status "Generating crypto material..."
    
    if [ ! -f "crypto-config.yaml" ]; then
        print_error "crypto-config.yaml not found!"
        exit 1
    fi
    
    cryptogen generate --config=./crypto-config.yaml
    
    if [ $? -eq 0 ]; then
        print_status "Crypto material generated successfully."
    else
        print_error "Failed to generate crypto material."
        exit 1
    fi
}

# Generate genesis block
generate_genesis() {
    print_status "Generating genesis block..."
    
    if [ ! -f "configtx.yaml" ]; then
        print_error "configtx.yaml not found!"
        exit 1
    fi
    
    # Set environment variables
    export FABRIC_CFG_PATH=$PWD
    
    # Create channel artifacts directory
    mkdir -p channel-artifacts
    
    # Generate genesis block
    configtxgen -profile HealthInsureChainGenesis -channelID system-channel -outputBlock ./channel-artifacts/genesis.block
    
    if [ $? -eq 0 ]; then
        print_status "Genesis block generated successfully."
    else
        print_error "Failed to generate genesis block."
        exit 1
    fi
}

# Generate channel configuration
generate_channel_config() {
    print_status "Generating channel configuration..."
    
    # Set environment variables
    export FABRIC_CFG_PATH=$PWD
    
    # Generate channel configuration transaction
    configtxgen -profile HealthInsureChainChannel -outputCreateChannelTx ./channel-artifacts/channel.tx -channelID healthinsurechain-channel
    
    if [ $? -eq 0 ]; then
        print_status "Channel configuration generated successfully."
    else
        print_error "Failed to generate channel configuration."
        exit 1
    fi
}

# Start the network
start_network() {
    print_status "Starting Fabric network..."
    
    if [ ! -f "docker-compose.yaml" ]; then
        print_error "docker-compose.yaml not found!"
        exit 1
    fi
    
    docker-compose up -d
    
    if [ $? -eq 0 ]; then
        print_status "Fabric network started successfully."
    else
        print_error "Failed to start Fabric network."
        exit 1
    fi
    
    # Wait for network to be ready
    print_status "Waiting for network to be ready..."
    sleep 30
}

# Create and join channel
create_channel() {
    print_status "Creating and joining channel..."
    
    # Wait for orderer to be ready
    sleep 10
    
    # Create channel
    docker exec cli.hospital peer channel create -o orderer.healthinsurechain.com:7050 -c healthinsurechain-channel -f ./channel-artifacts/channel.tx --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/healthinsurechain.com/orderers/orderer.healthinsurechain.com/msp/tlscacerts/tlsca.healthinsurechain.com-cert.pem
    
    if [ $? -eq 0 ]; then
        print_status "Channel created successfully."
    else
        print_error "Failed to create channel."
        exit 1
    fi
    
    # Join Hospital peer to channel
    docker exec cli.hospital peer channel join -b healthinsurechain-channel.block
    
    if [ $? -eq 0 ]; then
        print_status "Hospital peer joined channel successfully."
    else
        print_error "Failed to join Hospital peer to channel."
        exit 1
    fi
    
    # Join Insurance peer to channel
    docker exec cli.hospital bash -c "CORE_PEER_LOCALMSPID=InsuranceMSP CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/insurance.healthinsurechain.com/peers/peer0.insurance.healthinsurechain.com/tls/ca.crt CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/insurance.healthinsurechain.com/users/Admin@insurance.healthinsurechain.com/msp CORE_PEER_ADDRESS=peer0.insurance.healthinsurechain.com:7051 peer channel join -b healthinsurechain-channel.block"
    
    if [ $? -eq 0 ]; then
        print_status "Insurance peer joined channel successfully."
    else
        print_error "Failed to join Insurance peer to channel."
        exit 1
    fi
}

# Install and instantiate chaincode
deploy_chaincode() {
    print_status "Deploying chaincode..."
    
    # Wait for peers to be ready
    sleep 10
    
    # Install chaincode on Hospital peer
    docker exec cli.hospital peer lifecycle chaincode package healthinsurechain.tar.gz --path /opt/gopath/src/github.com/chaincode --lang golang --label healthinsurechain_1.0
    
    docker exec cli.hospital peer lifecycle chaincode install healthinsurechain.tar.gz
    
    # Get package ID
    PACKAGE_ID=$(docker exec cli.hospital peer lifecycle chaincode queryinstalled --output json | jq -r '.installed_chaincodes[0].package_id')
    
    # Approve chaincode for Hospital
    docker exec cli.hospital peer lifecycle chaincode approveformyorg -o orderer.healthinsurechain.com:7050 --channelID healthinsurechain-channel --name healthinsurechain --version 1.0 --package-id $PACKAGE_ID --sequence 1 --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/healthinsurechain.com/orderers/orderer.healthinsurechain.com/msp/tlscacerts/tlsca.healthinsurechain.com-cert.pem
    
    # Approve chaincode for Insurance
    docker exec cli.hospital bash -c "CORE_PEER_LOCALMSPID=InsuranceMSP CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/insurance.healthinsurechain.com/peers/peer0.insurance.healthinsurechain.com/tls/ca.crt CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/insurance.healthinsurechain.com/users/Admin@insurance.healthinsurechain.com/msp CORE_PEER_ADDRESS=peer0.insurance.healthinsurechain.com:7051 peer lifecycle chaincode install healthinsurechain.tar.gz"
    
    docker exec cli.hospital bash -c "CORE_PEER_LOCALMSPID=InsuranceMSP CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/insurance.healthinsurechain.com/peers/peer0.insurance.healthinsurechain.com/tls/ca.crt CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/insurance.healthinsurechain.com/users/Admin@insurance.healthinsurechain.com/msp CORE_PEER_ADDRESS=peer0.insurance.healthinsurechain.com:7051 peer lifecycle chaincode approveformyorg -o orderer.healthinsurechain.com:7050 --channelID healthinsurechain-channel --name healthinsurechain --version 1.0 --package-id $PACKAGE_ID --sequence 1 --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/healthinsurechain.com/orderers/orderer.healthinsurechain.com/msp/tlscacerts/tlsca.healthinsurechain.com-cert.pem"
    
    # Commit chaincode
    docker exec cli.hospital peer lifecycle chaincode commit -o orderer.healthinsurechain.com:7050 --channelID healthinsurechain-channel --name healthinsurechain --version 1.0 --sequence 1 --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/healthinsurechain.com/orderers/orderer.healthinsurechain.com/msp/tlscacerts/tlsca.healthinsurechain.com-cert.pem --peerAddresses peer0.hospital.healthinsurechain.com:7051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/hospital.healthinsurechain.com/peers/peer0.hospital.healthinsurechain.com/tls/ca.crt --peerAddresses peer0.insurance.healthinsurechain.com:7051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/insurance.healthinsurechain.com/peers/peer0.insurance.healthinsurechain.com/tls/ca.crt
    
    if [ $? -eq 0 ]; then
        print_status "Chaincode deployed successfully."
    else
        print_error "Failed to deploy chaincode."
        exit 1
    fi
}

# Initialize chaincode
initialize_chaincode() {
    print_status "Initializing chaincode..."
    
    docker exec cli.hospital peer chaincode invoke -o orderer.healthinsurechain.com:7050 --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/healthinsurechain.com/orderers/orderer.healthinsurechain.com/msp/tlscacerts/tlsca.healthinsurechain.com-cert.pem -C healthinsurechain-channel -n healthinsurechain --peerAddresses peer0.hospital.healthinsurechain.com:7051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/hospital.healthinsurechain.com/peers/peer0.hospital.healthinsurechain.com/tls/ca.crt --peerAddresses peer0.insurance.healthinsurechain.com:7051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/insurance.healthinsurechain.com/peers/peer0.insurance.healthinsurechain.com/tls/ca.crt -c '{"function":"InitLedger","Args":[]}'
    
    if [ $? -eq 0 ]; then
        print_status "Chaincode initialized successfully."
    else
        print_error "Failed to initialize chaincode."
        exit 1
    fi
}

# Main execution
main() {
    print_status "Starting HealthInsureChain Fabric Network Setup..."
    
    check_dependencies
    cleanup
    generate_crypto
    generate_genesis
    generate_channel_config
    start_network
    create_channel
    deploy_chaincode
    initialize_chaincode
    
    print_status "HealthInsureChain Fabric Network setup completed successfully!"
    print_status "Network is now running and ready for use."
    print_status ""
    print_status "Network endpoints:"
    print_status "  Orderer: localhost:7050"
    print_status "  Hospital Peer: localhost:7051"
    print_status "  Insurance Peer: localhost:8051"
    print_status "  Hospital CA: localhost:7054"
    print_status "  Insurance CA: localhost:8054"
    print_status ""
    print_status "You can now start the Fabric API server:"
    print_status "  cd ../fabric-api && npm start"
}

# Run main function
main "$@"
