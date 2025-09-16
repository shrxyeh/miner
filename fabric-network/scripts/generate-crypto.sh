#!/bin/bash

# Generate crypto material for HealthInsureChain network

echo "Generating crypto material for HealthInsureChain network..."

# Remove existing crypto material
rm -rf crypto-config

# Generate crypto material
cryptogen generate --config=./crypto-config.yaml

echo "Crypto material generated successfully!"

# Set proper permissions
chmod -R 755 crypto-config

echo "Permissions set for crypto material."
