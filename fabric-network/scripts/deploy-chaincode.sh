#!/bin/bash

# Deploy HealthInsureChain chaincode

CHANNEL_NAME="healthinsurechain-channel"
CHAINCODE_NAME="healthinsurechain"
CHAINCODE_VERSION="1.0"
CHAINCODE_PATH="github.com/chaincode/healthinsurechain"

echo "Deploying HealthInsureChain chaincode..."

# Set environment variables for Hospital peer
export CORE_PEER_LOCALMSPID=HospitalMSP
export CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/hospital.healthinsurechain.com/peers/peer0.hospital.healthinsurechain.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/hospital.healthinsurechain.com/users/Admin@hospital.healthinsurechain.com/msp
export CORE_PEER_ADDRESS=peer0.hospital.healthinsurechain.com:7051

# Package chaincode
peer lifecycle chaincode package ${CHAINCODE_NAME}.tar.gz --path ${CHAINCODE_PATH} --lang golang --label ${CHAINCODE_NAME}_${CHAINCODE_VERSION}

# Install chaincode on Hospital peer
peer lifecycle chaincode install ${CHAINCODE_NAME}.tar.gz

# Get package ID
PACKAGE_ID=$(peer lifecycle chaincode queryinstalled --output json | jq -r '.installed_chaincodes[0].package_id')

# Approve chaincode for Hospital
peer lifecycle chaincode approveformyorg -o orderer.healthinsurechain.com:7050 --channelID $CHANNEL_NAME --name $CHAINCODE_NAME --version $CHAINCODE_VERSION --package-id $PACKAGE_ID --sequence 1 --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/healthinsurechain.com/orderers/orderer.healthinsurechain.com/msp/tlscacerts/tlsca.healthinsurechain.com-cert.pem

# Set environment variables for Insurance peer
export CORE_PEER_LOCALMSPID=InsuranceMSP
export CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/insurance.healthinsurechain.com/peers/peer0.insurance.healthinsurechain.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/insurance.healthinsurechain.com/users/Admin@insurance.healthinsurechain.com/msp
export CORE_PEER_ADDRESS=peer0.insurance.healthinsurechain.com:7051

# Install chaincode on Insurance peer
peer lifecycle chaincode install ${CHAINCODE_NAME}.tar.gz

# Approve chaincode for Insurance
peer lifecycle chaincode approveformyorg -o orderer.healthinsurechain.com:7050 --channelID $CHANNEL_NAME --name $CHAINCODE_NAME --version $CHAINCODE_VERSION --package-id $PACKAGE_ID --sequence 1 --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/healthinsurechain.com/orderers/orderer.healthinsurechain.com/msp/tlscacerts/tlsca.healthinsurechain.com-cert.pem

# Commit chaincode
peer lifecycle chaincode commit -o orderer.healthinsurechain.com:7050 --channelID $CHANNEL_NAME --name $CHAINCODE_NAME --version $CHAINCODE_VERSION --sequence 1 --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/healthinsurechain.com/orderers/orderer.healthinsurechain.com/msp/tlscacerts/tlsca.healthinsurechain.com-cert.pem --peerAddresses peer0.hospital.healthinsurechain.com:7051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/hospital.healthinsurechain.com/peers/peer0.hospital.healthinsurechain.com/tls/ca.crt --peerAddresses peer0.insurance.healthinsurechain.com:7051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/insurance.healthinsurechain.com/peers/peer0.insurance.healthinsurechain.com/tls/ca.crt

echo "HealthInsureChain chaincode deployed successfully!"
