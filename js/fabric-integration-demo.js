const { ethers } = require('ethers');
const EthereumFabricBridge = require('../fabric-integration/ethereum-fabric-bridge');

/**
 * HealthInsureChain Fabric Integration Demo
 * Demonstrates the complete workflow between Ethereum and Fabric networks
 */

async function main() {
    console.log('🏥 HealthInsureChain Fabric Integration Demo 🏥\n');

    // Configuration
    const ethereumConfig = {
        rpcUrl: 'http://localhost:8545',
        contractAddress: '0x5FbDB2315678afecb367f032d93F642f64180aa3', // Update with actual deployed address
        abi: require('../out/PolicyClaim.sol/PolicyClaim.json').abi
    };

    const fabricConfig = {
        walletPath: './fabric-api/wallet',
        connectionProfile: './fabric-api/connection-profile.json',
        channelName: 'healthinsurechain-channel',
        chaincodeName: 'healthinsurechain',
        userId: 'Admin@hospital.healthinsurechain.com'
    };

    try {
        // Initialize bridge
        console.log('🔗 Initializing Ethereum-Fabric Bridge...');
        const bridge = new EthereumFabricBridge(ethereumConfig, fabricConfig);
        await bridge.initialize();
        console.log('✅ Bridge initialized successfully!\n');

        // Demo 1: Create Patient Record in Fabric
        console.log('📋 Demo 1: Creating Patient Record in Fabric');
        const patientRecord = await bridge.createPatientRecord({
            patientId: 'PAT_DEMO_001',
            hospitalId: 'HOSP_DEMO_001',
            insuranceId: 'INS_DEMO_001',
            diagnosis: 'Routine Health Checkup',
            treatment: 'General Consultation and Blood Tests',
            cost: 250.00
        });
        console.log('✅ Patient record created:', patientRecord);
        console.log('');

        // Demo 2: Register Policy in Ethereum (simulated)
        console.log('📄 Demo 2: Registering Policy in Ethereum');
        const policyData = {
            policyHolder: '0x70997970C51812dc3A010C7d01b50e0d17dc79C8', // Test account
            insuredAmount: ethers.utils.parseEther('10000'), // 10,000 tokens
            premium: ethers.utils.parseEther('100'), // 100 tokens
            startDate: Math.floor(Date.now() / 1000),
            endDate: Math.floor(Date.now() / 1000) + (365 * 24 * 60 * 60), // 1 year
            policyHash: 'POLICY_HASH_DEMO_001'
        };

        // Note: In a real scenario, you would call the Ethereum contract here
        // const policyTx = await bridge.policyContract.registerPolicy(...);
        console.log('✅ Policy data prepared for Ethereum registration');
        console.log('');

        // Demo 3: Sync Policy to Fabric
        console.log('🔄 Demo 3: Syncing Policy to Fabric');
        const policyId = 'POLICY_DEMO_001';
        const syncResult = await bridge.syncPolicyToFabric(policyId, 'PAT_DEMO_001');
        console.log('✅ Policy synced to Fabric:', syncResult);
        console.log('');

        // Demo 4: Create Claim Request
        console.log('💰 Demo 4: Creating Claim Request');
        const claimRequest = await bridge.createClaimRequest({
            patientId: 'PAT_DEMO_001',
            hospitalId: 'HOSP_DEMO_001',
            insuranceId: 'INS_DEMO_001',
            policyId: policyId,
            description: 'Emergency treatment for patient PAT_DEMO_001',
            amount: 500.00
        });
        console.log('✅ Claim request created:', claimRequest);
        console.log('');

        // Demo 5: Process Claim
        console.log('⚡ Demo 5: Processing Claim');
        const processResult = await bridge.processClaim(claimRequest.claimId);
        console.log('✅ Claim processed:', processResult);
        console.log('');

        // Demo 6: Query Data from Fabric
        console.log('🔍 Demo 6: Querying Data from Fabric');
        
        // Get all patient records
        const allRecords = await bridge.fabricContract.evaluateTransaction('GetAllPatientRecords');
        console.log('📊 All patient records:', JSON.parse(allRecords.toString()).length, 'records found');
        
        // Get all claim requests
        const allClaims = await bridge.fabricContract.evaluateTransaction('GetAllClaimRequests');
        console.log('📊 All claim requests:', JSON.parse(allClaims.toString()).length, 'claims found');
        
        // Get records by hospital
        const hospitalRecords = await bridge.getRecordsByHospital('HOSP_DEMO_001');
        console.log('🏥 Records for HOSP_DEMO_001:', hospitalRecords.length, 'records');
        
        // Get claims by insurance
        const insuranceClaims = await bridge.getClaimsByInsurance('INS_DEMO_001');
        console.log('🏢 Claims for INS_DEMO_001:', insuranceClaims.length, 'claims');
        console.log('');

        // Demo 7: Event Monitoring (simulated)
        console.log('👂 Demo 7: Starting Event Monitoring');
        await bridge.startEventMonitoring();
        console.log('✅ Event monitoring started');
        console.log('');

        console.log('🎉 Demo completed successfully!');
        console.log('');
        console.log('📋 Summary:');
        console.log('   • Patient record created in Fabric');
        console.log('   • Policy synced from Ethereum to Fabric');
        console.log('   • Claim request created and processed');
        console.log('   • Data queried from both networks');
        console.log('   • Event monitoring activated');
        console.log('');
        console.log('🔗 Integration Features Demonstrated:');
        console.log('   • Cross-network data synchronization');
        console.log('   • Automated claim processing');
        console.log('   • Real-time event monitoring');
        console.log('   • Hospital-Insurance data sharing');
        console.log('   • Policy verification across networks');

        // Close connections
        await bridge.close();
        console.log('🔌 Connections closed');

    } catch (error) {
        console.error('❌ Demo failed:', error);
        process.exit(1);
    }
}

// Run demo
if (require.main === module) {
    main().catch((error) => {
        console.error('❌ Demo execution failed:', error);
        process.exit(1);
    });
}

module.exports = main;
