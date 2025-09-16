const { ethers } = require('ethers');
const { Gateway, Wallets } = require('fabric-network');
const fs = require('fs');
const path = require('path');

/**
 * Ethereum-Fabric Bridge for HealthInsureChain
 * Handles data synchronization between Ethereum blockchain and Hyperledger Fabric
 */
class EthereumFabricBridge {
    constructor(ethereumConfig, fabricConfig) {
        this.ethereumConfig = ethereumConfig;
        this.fabricConfig = fabricConfig;
        this.ethereumProvider = null;
        this.policyContract = null;
        this.fabricGateway = null;
        this.fabricContract = null;
    }

    /**
     * Initialize Ethereum connection
     */
    async initializeEthereum() {
        try {
            this.ethereumProvider = new ethers.providers.JsonRpcProvider(this.ethereumConfig.rpcUrl);
            this.policyContract = new ethers.Contract(
                this.ethereumConfig.contractAddress,
                this.ethereumConfig.abi,
                this.ethereumProvider
            );
            console.log('Ethereum connection initialized successfully');
        } catch (error) {
            console.error('Failed to initialize Ethereum connection:', error);
            throw error;
        }
    }

    /**
     * Initialize Fabric connection
     */
    async initializeFabric() {
        try {
            const wallet = await Wallets.newFileSystemWallet(this.fabricConfig.walletPath);
            
            const gateway = new Gateway();
            await gateway.connect(this.fabricConfig.connectionProfile, {
                wallet,
                identity: this.fabricConfig.userId,
                discovery: { enabled: true, asLocalhost: true }
            });

            const network = await gateway.getNetwork(this.fabricConfig.channelName);
            this.fabricContract = network.getContract(this.fabricConfig.chaincodeName);
            this.fabricGateway = gateway;

            console.log('Fabric connection initialized successfully');
        } catch (error) {
            console.error('Failed to initialize Fabric connection:', error);
            throw error;
        }
    }

    /**
     * Initialize both connections
     */
    async initialize() {
        await this.initializeEthereum();
        await this.initializeFabric();
        console.log('Ethereum-Fabric bridge initialized successfully');
    }

    /**
     * Sync policy data from Ethereum to Fabric
     */
    async syncPolicyToFabric(policyId, patientId) {
        try {
            // Get policy data from Ethereum
            const policy = await this.policyContract.getPolicy(policyId);
            
            // Verify policy validity
            const isValid = await this.policyContract.isPolicyValidForClaims(policyId);
            
            // Convert Ethereum data to Fabric format
            const policyData = {
                policyId: policyId,
                patientId: patientId,
                isValid: isValid,
                coverageAmount: parseFloat(ethers.utils.formatEther(policy.insuredAmount)),
                expiryDate: new Date(parseInt(policy.endDate) * 1000),
                ethereumTxHash: 'sync-' + Date.now()
            };

            // Store in Fabric
            await this.fabricContract.submitTransaction(
                'VerifyPolicyWithEthereum',
                policyData.policyId,
                policyData.patientId,
                policyData.isValid,
                policyData.coverageAmount,
                policyData.expiryDate.toISOString(),
                policyData.ethereumTxHash
            );

            console.log(`Policy ${policyId} synced to Fabric successfully`);
            return policyData;
        } catch (error) {
            console.error(`Failed to sync policy ${policyId} to Fabric:`, error);
            throw error;
        }
    }

    /**
     * Create claim request in Fabric and submit to Ethereum
     */
    async createClaimRequest(claimData) {
        try {
            // Create claim request in Fabric
            const claimId = `CLAIM_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
            
            await this.fabricContract.submitTransaction(
                'CreateClaimRequest',
                claimId,
                claimData.patientId,
                claimData.hospitalId,
                claimData.insuranceId,
                claimData.description,
                claimData.policyId,
                claimData.amount
            );

            // Submit claim to Ethereum
            const ethereumTx = await this.policyContract.submitClaim(
                claimData.policyId,
                ethers.utils.parseEther(claimData.amount.toString()),
                claimData.description
            );

            const receipt = await ethereumTx.wait();
            const ethereumTxHash = receipt.transactionHash;

            // Update Fabric with Ethereum transaction hash
            await this.fabricContract.submitTransaction(
                'UpdateClaimStatus',
                claimId,
                'submitted',
                ethereumTxHash
            );

            console.log(`Claim ${claimId} created successfully`);
            return {
                claimId,
                ethereumTxHash,
                status: 'submitted'
            };
        } catch (error) {
            console.error('Failed to create claim request:', error);
            throw error;
        }
    }

    /**
     * Process claim and sync status between networks
     */
    async processClaim(claimId) {
        try {
            // Get claim data from Fabric
            const claimBuffer = await this.fabricContract.evaluateTransaction('GetClaimRequest', claimId);
            const claim = JSON.parse(claimBuffer.toString());

            // Process claim in Ethereum
            const ethereumTx = await this.policyContract.processClaim(claim.policyId);
            const receipt = await ethereumTx.wait();

            // Get updated claim status from Ethereum
            const updatedClaim = await this.policyContract.getClaim(claimId);
            const status = updatedClaim.status === 1 ? 'approved' : 'rejected';

            // Update Fabric with new status
            await this.fabricContract.submitTransaction(
                'UpdateClaimStatus',
                claimId,
                status,
                receipt.transactionHash
            );

            console.log(`Claim ${claimId} processed with status: ${status}`);
            return {
                claimId,
                status,
                ethereumTxHash: receipt.transactionHash
            };
        } catch (error) {
            console.error(`Failed to process claim ${claimId}:`, error);
            throw error;
        }
    }

    /**
     * Create patient record in Fabric
     */
    async createPatientRecord(patientData) {
        try {
            const recordHash = ethers.utils.keccak256(
                ethers.utils.defaultAbiCoder.encode(
                    ['string', 'string', 'string', 'uint256'],
                    [patientData.patientId, patientData.diagnosis, patientData.treatment, patientData.cost]
                )
            );

            await this.fabricContract.submitTransaction(
                'CreatePatientRecord',
                patientData.patientId,
                patientData.hospitalId,
                patientData.insuranceId,
                recordHash,
                patientData.diagnosis,
                patientData.treatment,
                patientData.cost
            );

            console.log(`Patient record created for ${patientData.patientId}`);
            return {
                patientId: patientData.patientId,
                recordHash: recordHash
            };
        } catch (error) {
            console.error('Failed to create patient record:', error);
            throw error;
        }
    }

    /**
     * Get all claims for an insurance company
     */
    async getClaimsByInsurance(insuranceId) {
        try {
            const claimsBuffer = await this.fabricContract.evaluateTransaction(
                'QueryClaimsByInsurance',
                insuranceId
            );
            return JSON.parse(claimsBuffer.toString());
        } catch (error) {
            console.error(`Failed to get claims for insurance ${insuranceId}:`, error);
            throw error;
        }
    }

    /**
     * Get all records for a hospital
     */
    async getRecordsByHospital(hospitalId) {
        try {
            const recordsBuffer = await this.fabricContract.evaluateTransaction(
                'QueryRecordsByHospital',
                hospitalId
            );
            return JSON.parse(recordsBuffer.toString());
        } catch (error) {
            console.error(`Failed to get records for hospital ${hospitalId}:`, error);
            throw error;
        }
    }

    /**
     * Monitor Ethereum events and sync to Fabric
     */
    async startEventMonitoring() {
        try {
            // Monitor policy registration events
            this.policyContract.on('PolicyRegistered', async (policyId, policyHolder, insuredAmount, premium, startDate, endDate, event) => {
                console.log('Policy registered event detected:', policyId);
                // Sync to Fabric if needed
                // await this.syncPolicyToFabric(policyId, policyHolder);
            });

            // Monitor claim submission events
            this.policyContract.on('ClaimSubmitted', async (claimId, policyId, claimant, claimAmount, claimDescription, event) => {
                console.log('Claim submitted event detected:', claimId);
                // Update Fabric with claim status
            });

            // Monitor claim processing events
            this.policyContract.on('ClaimProcessed', async (claimId, policyId, status, reason, event) => {
                console.log('Claim processed event detected:', claimId, status);
                // Sync status to Fabric
            });

            console.log('Event monitoring started');
        } catch (error) {
            console.error('Failed to start event monitoring:', error);
            throw error;
        }
    }

    /**
     * Close connections
     */
    async close() {
        if (this.fabricGateway) {
            await this.fabricGateway.disconnect();
        }
        console.log('Connections closed');
    }
}

module.exports = EthereumFabricBridge;
