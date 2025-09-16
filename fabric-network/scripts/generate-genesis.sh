#!/bin/bash

# Generate genesis block for HealthInsureChain network

echo "Generating genesis block for HealthInsureChain network..."

# Remove existing channel artifacts
rm -rf channel-artifacts
mkdir channel-artifacts

# Generate genesis block
configtxgen -profile HealthInsureChainGenesis -channelID system-channel -outputBlock ./channel-artifacts/genesis.block

echo "Genesis block generated successfully!"

# Set proper permissions
chmod -R 755 channel-artifacts

echo "Permissions set for channel artifacts."
