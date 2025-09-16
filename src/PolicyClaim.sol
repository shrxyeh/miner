// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title PolicyClaim
 * @dev Health Insurance Claim Verification Smart Contract
 * @notice Automates insurance approvals and claim validation on Ethereum private chain
 */
contract PolicyClaim {
    // Struct to store policy information
    struct Policy {
        bytes32 policyId;
        address policyHolder;
        uint256 insuredAmount;
        uint256 premium;
        uint256 startDate;
        uint256 endDate;
        bool isActive;
        string policyHash; 
    }

    // Struct to store claim information
    struct Claim {
        bytes32 claimId;
        bytes32 policyId;
        address claimant;
        uint256 claimAmount;
        string claimDescription;
        uint256 submissionDate;
        ClaimStatus status;
        string rejectionReason;
    }

    // Enum for claim status
    enum ClaimStatus {
        Pending,
        Approved,
        Rejected
    }

    // State variables
    address public insurer;
    uint256 public totalPolicies;
    uint256 public totalClaims;
    uint256 public constant MINIMUM_PREMIUM = 0.01 ether;
    uint256 public constant MAXIMUM_CLAIM_RATIO = 80; // Maximum 80% of insured amount can be claimed

    // Mappings
    mapping(bytes32 => Policy) public policies;
    mapping(bytes32 => Claim) public claims;
    mapping(address => bytes32[]) public userPolicies;
    mapping(address => bytes32[]) public userClaims;

    // Events
    event PolicyRegistered(
        bytes32 indexed policyId,
        address indexed policyHolder,
        uint256 insuredAmount,
        uint256 premium,
        uint256 startDate,
        uint256 endDate
    );

    event ClaimSubmitted(
        bytes32 indexed claimId,
        bytes32 indexed policyId,
        address indexed claimant,
        uint256 claimAmount,
        string claimDescription
    );

    event ClaimProcessed(
        bytes32 indexed claimId,
        bytes32 indexed policyId,
        ClaimStatus status,
        string reason
    );

    event PolicyDeactivated(bytes32 indexed policyId, address indexed policyHolder);

    // Modifiers
    modifier onlyInsurer() {
        require(msg.sender == insurer, "Only insurer can perform this action");
        _;
    }

    modifier validPolicy(bytes32 _policyId) {
        require(policies[_policyId].policyId != bytes32(0), "Policy does not exist");
        require(policies[_policyId].isActive, "Policy is not active");
        _;
    }

    modifier validClaim(bytes32 _claimId) {
        require(claims[_claimId].claimId != bytes32(0), "Claim does not exist");
        _;
    }

    constructor() {
        insurer = msg.sender;
    }

    /**
     * @dev Register a new insurance policy
     * @param _policyHolder Address of the policy holder
     * @param _insuredAmount Maximum amount that can be claimed
     * @param _premium Premium amount paid
     * @param _startDate Policy start date (timestamp)
     * @param _endDate Policy end date (timestamp)
     * @param _policyHash Hash of the policy document
     * @return policyId The unique identifier for the policy
     */
    function registerPolicy(
        address _policyHolder,
        uint256 _insuredAmount,
        uint256 _premium,
        uint256 _startDate,
        uint256 _endDate,
        string memory _policyHash
    ) external onlyInsurer returns (bytes32) {
        require(_policyHolder != address(0), "Invalid policy holder address");
        require(_insuredAmount > 0, "Insured amount must be greater than 0");
        require(_premium >= MINIMUM_PREMIUM, "Premium below minimum required");
        require(_endDate > _startDate, "End date must be after start date");
        require(_endDate > block.timestamp, "End date must be in the future");

        bytes32 policyId = keccak256(
            abi.encodePacked(
                _policyHolder,
                _insuredAmount,
                _premium,
                _startDate,
                _endDate,
                block.timestamp,
                totalPolicies
            )
        );

        policies[policyId] = Policy({
            policyId: policyId,
            policyHolder: _policyHolder,
            insuredAmount: _insuredAmount,
            premium: _premium,
            startDate: _startDate,
            endDate: _endDate,
            isActive: true,
            policyHash: _policyHash
        });

        userPolicies[_policyHolder].push(policyId);
        totalPolicies++;

        emit PolicyRegistered(
            policyId,
            _policyHolder,
            _insuredAmount,
            _premium,
            _startDate,
            _endDate
        );

        return policyId;
    }

    /**
     * @dev Submit a claim for a policy
     * @param _policyId The policy ID to claim against
     * @param _claimAmount The amount being claimed
     * @param _claimDescription Description of the claim
     * @return claimId The unique identifier for the claim
     */
    function submitClaim(
        bytes32 _policyId,
        uint256 _claimAmount,
        string memory _claimDescription
    ) external validPolicy(_policyId) returns (bytes32) {
        Policy storage policy = policies[_policyId];
        
        require(msg.sender == policy.policyHolder, "Only policy holder can submit claims");
        require(_claimAmount > 0, "Claim amount must be greater than 0");
        require(block.timestamp >= policy.startDate, "Policy has not started yet");
        require(block.timestamp <= policy.endDate, "Policy has expired");

        bytes32 claimId = keccak256(
            abi.encodePacked(
                _policyId,
                msg.sender,
                _claimAmount,
                _claimDescription,
                block.timestamp,
                totalClaims
            )
        );

        claims[claimId] = Claim({
            claimId: claimId,
            policyId: _policyId,
            claimant: msg.sender,
            claimAmount: _claimAmount,
            claimDescription: _claimDescription,
            submissionDate: block.timestamp,
            status: ClaimStatus.Pending,
            rejectionReason: ""
        });

        userClaims[msg.sender].push(claimId);
        totalClaims++;

        emit ClaimSubmitted(claimId, _policyId, msg.sender, _claimAmount, _claimDescription);

        return claimId;
    }

    /**
     * @dev Automatically verify and process a claim
     * @param _claimId The claim ID to process
     * @return approved Whether the claim was approved
     */
    function processClaim(bytes32 _claimId) external validClaim(_claimId) returns (bool) {
        Claim storage claim = claims[_claimId];
        Policy storage policy = policies[claim.policyId];

        require(claim.status == ClaimStatus.Pending, "Claim already processed");

        // Verification conditions
        bool isPolicyValid = policy.isActive && 
                           block.timestamp >= policy.startDate && 
                           block.timestamp <= policy.endDate;
        
        bool isAmountValid = claim.claimAmount <= policy.insuredAmount;
        
        // Check if claim amount is within reasonable limits (max 80% of insured amount)
        bool isAmountReasonable = (claim.claimAmount * 100) / policy.insuredAmount <= MAXIMUM_CLAIM_RATIO;

        bool approved = isPolicyValid && isAmountValid && isAmountReasonable;

        if (approved) {
            claim.status = ClaimStatus.Approved;
            // In a real implementation, you would transfer funds here
            // payable(claim.claimant).transfer(claim.claimAmount);
        } else {
            claim.status = ClaimStatus.Rejected;
            if (!isPolicyValid) {
                claim.rejectionReason = "Policy is not valid or has expired";
            } else if (!isAmountValid) {
                claim.rejectionReason = "Claim amount exceeds insured amount";
            } else if (!isAmountReasonable) {
                claim.rejectionReason = "Claim amount exceeds maximum allowed ratio";
            }
        }

        emit ClaimProcessed(
            _claimId,
            claim.policyId,
            claim.status,
            claim.rejectionReason
        );

        return approved;
    }

    /**
     * @dev Deactivate a policy
     * @param _policyId The policy ID to deactivate
     */
    function deactivatePolicy(bytes32 _policyId) external onlyInsurer validPolicy(_policyId) {
        policies[_policyId].isActive = false;
        emit PolicyDeactivated(_policyId, policies[_policyId].policyHolder);
    }

    /**
     * @dev Get policy information
     * @param _policyId The policy ID
     * @return Policy struct containing policy details
     */
    function getPolicy(bytes32 _policyId) external view returns (Policy memory) {
        require(policies[_policyId].policyId != bytes32(0), "Policy does not exist");
        return policies[_policyId];
    }

    /**
     * @dev Get claim information
     * @param _claimId The claim ID
     * @return Claim struct containing claim details
     */
    function getClaim(bytes32 _claimId) external view returns (Claim memory) {
        require(claims[_claimId].claimId != bytes32(0), "Claim does not exist");
        return claims[_claimId];
    }

    /**
     * @dev Get all policies for a user
     * @param _user The user address
     * @return Array of policy IDs
     */
    function getUserPolicies(address _user) external view returns (bytes32[] memory) {
        return userPolicies[_user];
    }

    /**
     * @dev Get all claims for a user
     * @param _user The user address
     * @return Array of claim IDs
     */
    function getUserClaims(address _user) external view returns (bytes32[] memory) {
        return userClaims[_user];
    }

    /**
     * @dev Get contract statistics
     * @return totalPolicies Total number of registered policies
     * @return totalClaims Total number of submitted claims
     * @return activePolicies Number of active policies
     */
    function getContractStats() external view returns (uint256, uint256, uint256) {
        uint256 activePolicies = 0;
        // Note: In a real implementation, you'd want to track this more efficiently
        // This is a simplified version for demonstration
        return (totalPolicies, totalClaims, activePolicies);
    }

    /**
     * @dev Check if a policy is valid for claims
     * @param _policyId The policy ID to check
     * @return valid Whether the policy is valid for claims
     */
    function isPolicyValidForClaims(bytes32 _policyId) external view returns (bool) {
        Policy memory policy = policies[_policyId];
        return policy.policyId != bytes32(0) && 
               policy.isActive && 
               block.timestamp >= policy.startDate && 
               block.timestamp <= policy.endDate;
    }
}
