const express = require('express');
const cors = require('cors');
const EthereumFabricBridge = require('../fabric-integration/ethereum-fabric-bridge');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 3001;

// Middleware
app.use(cors());
app.use(express.json());

// Configuration
const ethereumConfig = {
    rpcUrl: process.env.ETHEREUM_RPC_URL || 'http://localhost:8545',
    contractAddress: process.env.CONTRACT_ADDRESS || '0x5FbDB2315678afecb367f032d93F642f64180aa3',
    abi: require('../out/PolicyClaim.sol/PolicyClaim.json').abi
};

const fabricConfig = {
    walletPath: path.join(__dirname, 'wallet'),
    connectionProfile: path.join(__dirname, 'connection-profile.json'),
    channelName: 'healthinsurechain-channel',
    chaincodeName: 'healthinsurechain',
    userId: 'Admin@hospital.healthinsurechain.com'
};

// Initialize bridge
const bridge = new EthereumFabricBridge(ethereumConfig, fabricConfig);

// Initialize connections
bridge.initialize().catch(console.error);

// Routes

/**
 * Health check endpoint
 */
app.get('/health', (req, res) => {
    res.json({ 
        status: 'healthy', 
        timestamp: new Date().toISOString(),
        services: {
            ethereum: 'connected',
            fabric: 'connected'
        }
    });
});

/**
 * Create a new patient record
 */
app.post('/api/patient-records', async (req, res) => {
    try {
        const { patientId, hospitalId, insuranceId, diagnosis, treatment, cost } = req.body;
        
        if (!patientId || !hospitalId || !insuranceId || !diagnosis || !treatment || !cost) {
            return res.status(400).json({ error: 'Missing required fields' });
        }

        const result = await bridge.createPatientRecord({
            patientId,
            hospitalId,
            insuranceId,
            diagnosis,
            treatment,
            cost: parseFloat(cost)
        });

        res.json({ success: true, data: result });
    } catch (error) {
        console.error('Error creating patient record:', error);
        res.status(500).json({ error: error.message });
    }
});

/**
 * Create a new claim request
 */
app.post('/api/claims', async (req, res) => {
    try {
        const { patientId, hospitalId, insuranceId, policyId, description, amount } = req.body;
        
        if (!patientId || !hospitalId || !insuranceId || !policyId || !description || !amount) {
            return res.status(400).json({ error: 'Missing required fields' });
        }

        const result = await bridge.createClaimRequest({
            patientId,
            hospitalId,
            insuranceId,
            policyId,
            description,
            amount: parseFloat(amount)
        });

        res.json({ success: true, data: result });
    } catch (error) {
        console.error('Error creating claim request:', error);
        res.status(500).json({ error: error.message });
    }
});

/**
 * Process a claim
 */
app.post('/api/claims/:claimId/process', async (req, res) => {
    try {
        const { claimId } = req.params;
        
        const result = await bridge.processClaim(claimId);
        res.json({ success: true, data: result });
    } catch (error) {
        console.error('Error processing claim:', error);
        res.status(500).json({ error: error.message });
    }
});

/**
 * Get claims by insurance company
 */
app.get('/api/claims/insurance/:insuranceId', async (req, res) => {
    try {
        const { insuranceId } = req.params;
        
        const claims = await bridge.getClaimsByInsurance(insuranceId);
        res.json({ success: true, data: claims });
    } catch (error) {
        console.error('Error getting claims by insurance:', error);
        res.status(500).json({ error: error.message });
    }
});

/**
 * Get patient records by hospital
 */
app.get('/api/patient-records/hospital/:hospitalId', async (req, res) => {
    try {
        const { hospitalId } = req.params;
        
        const records = await bridge.getRecordsByHospital(hospitalId);
        res.json({ success: true, data: records });
    } catch (error) {
        console.error('Error getting records by hospital:', error);
        res.status(500).json({ error: error.message });
    }
});

/**
 * Sync policy from Ethereum to Fabric
 */
app.post('/api/sync-policy', async (req, res) => {
    try {
        const { policyId, patientId } = req.body;
        
        if (!policyId || !patientId) {
            return res.status(400).json({ error: 'Missing policyId or patientId' });
        }

        const result = await bridge.syncPolicyToFabric(policyId, patientId);
        res.json({ success: true, data: result });
    } catch (error) {
        console.error('Error syncing policy:', error);
        res.status(500).json({ error: error.message });
    }
});

/**
 * Get all patient records
 */
app.get('/api/patient-records', async (req, res) => {
    try {
        const recordsBuffer = await bridge.fabricContract.evaluateTransaction('GetAllPatientRecords');
        const records = JSON.parse(recordsBuffer.toString());
        res.json({ success: true, data: records });
    } catch (error) {
        console.error('Error getting all patient records:', error);
        res.status(500).json({ error: error.message });
    }
});

/**
 * Get all claim requests
 */
app.get('/api/claims', async (req, res) => {
    try {
        const claimsBuffer = await bridge.fabricContract.evaluateTransaction('GetAllClaimRequests');
        const claims = JSON.parse(claimsBuffer.toString());
        res.json({ success: true, data: claims });
    } catch (error) {
        console.error('Error getting all claims:', error);
        res.status(500).json({ error: error.message });
    }
});

/**
 * Get specific patient record
 */
app.get('/api/patient-records/:patientId', async (req, res) => {
    try {
        const { patientId } = req.params;
        
        const recordBuffer = await bridge.fabricContract.evaluateTransaction('GetPatientRecord', patientId);
        const record = JSON.parse(recordBuffer.toString());
        res.json({ success: true, data: record });
    } catch (error) {
        console.error('Error getting patient record:', error);
        res.status(500).json({ error: error.message });
    }
});

/**
 * Get specific claim request
 */
app.get('/api/claims/:claimId', async (req, res) => {
    try {
        const { claimId } = req.params;
        
        const claimBuffer = await bridge.fabricContract.evaluateTransaction('GetClaimRequest', claimId);
        const claim = JSON.parse(claimBuffer.toString());
        res.json({ success: true, data: claim });
    } catch (error) {
        console.error('Error getting claim request:', error);
        res.status(500).json({ error: error.message });
    }
});

// Error handling middleware
app.use((err, req, res, next) => {
    console.error('Unhandled error:', err);
    res.status(500).json({ error: 'Internal server error' });
});

// 404 handler
app.use('*', (req, res) => {
    res.status(404).json({ error: 'Endpoint not found' });
});

// Start server
app.listen(PORT, () => {
    console.log(`Fabric API server running on port ${PORT}`);
    console.log(`Health check: http://localhost:${PORT}/health`);
});

// Graceful shutdown
process.on('SIGINT', async () => {
    console.log('Shutting down server...');
    await bridge.close();
    process.exit(0);
});

module.exports = app;
