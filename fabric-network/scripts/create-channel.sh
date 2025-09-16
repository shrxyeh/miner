#!/bin/bash

# Create and join channel for HealthInsureChain network

CHANNEL_NAME="healthinsurechain-channel"
CHANNEL_PROFILE="HealthInsureChainChannel"

echo "Creating channel $CHANNEL_NAME..."

# Generate channel configuration transaction
configtxgen -profile $CHANNEL_PROFILE -outputCreateChannelTx ./channel-artifacts/channel.tx -channelID $CHANNEL_NAME

echo "Channel configuration transaction generated!"

# Set proper permissions
chmod -R 755 channel-artifacts

echo "Channel creation script completed!"
