package main

import (
	"encoding/json"
	"fmt"
	"strconv"
	"time"

	"github.com/hyperledger/fabric-contract-api-go/contractapi"
)

// HealthInsureChainContract provides functions for managing health insurance data sharing
type HealthInsureChainContract struct {
	contractapi.Contract
}

// PatientRecord represents a patient's medical record
type PatientRecord struct {
	PatientID     string    `json:"patientId"`
	HospitalID    string    `json:"hospitalId"`
	InsuranceID   string    `json:"insuranceId"`
	RecordHash    string    `json:"recordHash"`
	Diagnosis     string    `json:"diagnosis"`
	Treatment     string    `json:"treatment"`
	Cost          float64   `json:"cost"`
	Date          time.Time `json:"date"`
	Status        string    `json:"status"` // "pending", "approved", "rejected"
	EthereumTxHash string   `json:"ethereumTxHash"`
	CreatedAt     time.Time `json:"createdAt"`
	UpdatedAt     time.Time `json:"updatedAt"`
}

// ClaimRequest represents a claim request from hospital to insurance
type ClaimRequest struct {
	ClaimID       string    `json:"claimId"`
	PatientID     string    `json:"patientId"`
	HospitalID    string    `json:"hospitalId"`
	InsuranceID   string    `json:"insuranceId"`
	Amount        float64   `json:"amount"`
	Description   string    `json:"description"`
	PolicyID      string    `json:"policyId"`
	Status        string    `json:"status"` // "submitted", "under_review", "approved", "rejected"
	EthereumTxHash string   `json:"ethereumTxHash"`
	CreatedAt     time.Time `json:"createdAt"`
	UpdatedAt     time.Time `json:"updatedAt"`
}

// PolicyVerification represents verification data from Ethereum
type PolicyVerification struct {
	PolicyID      string    `json:"policyId"`
	PatientID     string    `json:"patientId"`
	IsValid       bool      `json:"isValid"`
	CoverageAmount float64   `json:"coverageAmount"`
	ExpiryDate    time.Time `json:"expiryDate"`
	EthereumTxHash string   `json:"ethereumTxHash"`
	VerifiedAt    time.Time `json:"verifiedAt"`
}

// InitLedger adds a base set of records to the ledger
func (s *HealthInsureChainContract) InitLedger(ctx contractapi.TransactionContextInterface) error {
	records := []PatientRecord{
		{
			PatientID:   "PAT001",
			HospitalID:  "HOSP001",
			InsuranceID: "INS001",
			RecordHash:  "hash001",
			Diagnosis:   "Routine Checkup",
			Treatment:   "General Consultation",
			Cost:        150.00,
			Date:        time.Now(),
			Status:      "pending",
			CreatedAt:   time.Now(),
			UpdatedAt:   time.Now(),
		},
	}

	for _, record := range records {
		recordJSON, err := json.Marshal(record)
		if err != nil {
			return err
		}

		err = ctx.GetStub().PutState(record.PatientID, recordJSON)
		if err != nil {
			return fmt.Errorf("failed to put to world state. %v", err)
		}
	}

	return nil
}

// CreatePatientRecord creates a new patient record
func (s *HealthInsureChainContract) CreatePatientRecord(ctx contractapi.TransactionContextInterface, patientID, hospitalID, insuranceID, recordHash, diagnosis, treatment string, cost float64) error {
	exists, err := s.PatientRecordExists(ctx, patientID)
	if err != nil {
		return err
	}
	if exists {
		return fmt.Errorf("patient record %s already exists", patientID)
	}

	record := PatientRecord{
		PatientID:   patientID,
		HospitalID:  hospitalID,
		InsuranceID: insuranceID,
		RecordHash:  recordHash,
		Diagnosis:   diagnosis,
		Treatment:   treatment,
		Cost:        cost,
		Date:        time.Now(),
		Status:      "pending",
		CreatedAt:   time.Now(),
		UpdatedAt:   time.Now(),
	}

	recordJSON, err := json.Marshal(record)
	if err != nil {
		return err
	}

	return ctx.GetStub().PutState(patientID, recordJSON)
}

// CreateClaimRequest creates a new claim request
func (s *HealthInsureChainContract) CreateClaimRequest(ctx contractapi.TransactionContextInterface, claimID, patientID, hospitalID, insuranceID, description, policyID string, amount float64) error {
	exists, err := s.ClaimRequestExists(ctx, claimID)
	if err != nil {
		return err
	}
	if exists {
		return fmt.Errorf("claim request %s already exists", claimID)
	}

	claim := ClaimRequest{
		ClaimID:     claimID,
		PatientID:   patientID,
		HospitalID:  hospitalID,
		InsuranceID: insuranceID,
		Amount:      amount,
		Description: description,
		PolicyID:    policyID,
		Status:      "submitted",
		CreatedAt:   time.Now(),
		UpdatedAt:   time.Now(),
	}

	claimJSON, err := json.Marshal(claim)
	if err != nil {
		return err
	}

	return ctx.GetStub().PutState(claimID, claimJSON)
}

// UpdateClaimStatus updates the status of a claim request
func (s *HealthInsureChainContract) UpdateClaimStatus(ctx contractapi.TransactionContextInterface, claimID, status, ethereumTxHash string) error {
	claim, err := s.GetClaimRequest(ctx, claimID)
	if err != nil {
		return err
	}

	claim.Status = status
	claim.EthereumTxHash = ethereumTxHash
	claim.UpdatedAt = time.Now()

	claimJSON, err := json.Marshal(claim)
	if err != nil {
		return err
	}

	return ctx.GetStub().PutState(claimID, claimJSON)
}

// VerifyPolicyWithEthereum verifies policy data from Ethereum blockchain
func (s *HealthInsureChainContract) VerifyPolicyWithEthereum(ctx contractapi.TransactionContextInterface, policyID, patientID string, isValid bool, coverageAmount float64, expiryDate time.Time, ethereumTxHash string) error {
	verification := PolicyVerification{
		PolicyID:       policyID,
		PatientID:      patientID,
		IsValid:        isValid,
		CoverageAmount: coverageAmount,
		ExpiryDate:     expiryDate,
		EthereumTxHash: ethereumTxHash,
		VerifiedAt:     time.Now(),
	}

	verificationKey := fmt.Sprintf("VERIFICATION_%s_%s", policyID, patientID)
	verificationJSON, err := json.Marshal(verification)
	if err != nil {
		return err
	}

	return ctx.GetStub().PutState(verificationKey, verificationJSON)
}

// GetPatientRecord returns the patient record stored in the world state with given id
func (s *HealthInsureChainContract) GetPatientRecord(ctx contractapi.TransactionContextInterface, patientID string) (*PatientRecord, error) {
	recordJSON, err := ctx.GetStub().GetState(patientID)
	if err != nil {
		return nil, fmt.Errorf("failed to read from world state: %v", err)
	}
	if recordJSON == nil {
		return nil, fmt.Errorf("patient record %s does not exist", patientID)
	}

	var record PatientRecord
	err = json.Unmarshal(recordJSON, &record)
	if err != nil {
		return nil, err
	}

	return &record, nil
}

// GetClaimRequest returns the claim request stored in the world state with given id
func (s *HealthInsureChainContract) GetClaimRequest(ctx contractapi.TransactionContextInterface, claimID string) (*ClaimRequest, error) {
	claimJSON, err := ctx.GetStub().GetState(claimID)
	if err != nil {
		return nil, fmt.Errorf("failed to read from world state: %v", err)
	}
	if claimJSON == nil {
		return nil, fmt.Errorf("claim request %s does not exist", claimID)
	}

	var claim ClaimRequest
	err = json.Unmarshal(claimJSON, &claim)
	if err != nil {
		return nil, err
	}

	return &claim, nil
}

// GetAllPatientRecords returns all patient records found in world state
func (s *HealthInsureChainContract) GetAllPatientRecords(ctx contractapi.TransactionContextInterface) ([]*PatientRecord, error) {
	resultsIterator, err := ctx.GetStub().GetStateByRange("", "")
	if err != nil {
		return nil, err
	}
	defer resultsIterator.Close()

	var records []*PatientRecord
	for resultsIterator.HasNext() {
		queryResponse, err := resultsIterator.Next()
		if err != nil {
			return nil, err
		}

		var record PatientRecord
		err = json.Unmarshal(queryResponse.Value, &record)
		if err != nil {
			return nil, err
		}
		records = append(records, &record)
	}

	return records, nil
}

// GetAllClaimRequests returns all claim requests found in world state
func (s *HealthInsureChainContract) GetAllClaimRequests(ctx contractapi.TransactionContextInterface) ([]*ClaimRequest, error) {
	resultsIterator, err := ctx.GetStub().GetStateByRange("", "")
	if err != nil {
		return nil, err
	}
	defer resultsIterator.Close()

	var claims []*ClaimRequest
	for resultsIterator.HasNext() {
		queryResponse, err := resultsIterator.Next()
		if err != nil {
			return nil, err
		}

		var claim ClaimRequest
		err = json.Unmarshal(queryResponse.Value, &claim)
		if err != nil {
			return nil, err
		}
		claims = append(claims, &claim)
	}

	return claims, nil
}

// QueryRecordsByHospital returns all records for a specific hospital
func (s *HealthInsureChainContract) QueryRecordsByHospital(ctx contractapi.TransactionContextInterface, hospitalID string) ([]*PatientRecord, error) {
	queryString := fmt.Sprintf(`{"selector":{"hospitalId":"%s"}}`, hospitalID)
	return getQueryResultsForPatientRecords(ctx, queryString)
}

// QueryClaimsByInsurance returns all claims for a specific insurance company
func (s *HealthInsureChainContract) QueryClaimsByInsurance(ctx contractapi.TransactionContextInterface, insuranceID string) ([]*ClaimRequest, error) {
	queryString := fmt.Sprintf(`{"selector":{"insuranceId":"%s"}}`, insuranceID)
	return getQueryResultsForClaimRequests(ctx, queryString)
}

// PatientRecordExists returns true when patient record with given ID exists in world state
func (s *HealthInsureChainContract) PatientRecordExists(ctx contractapi.TransactionContextInterface, patientID string) (bool, error) {
	recordJSON, err := ctx.GetStub().GetState(patientID)
	if err != nil {
		return false, fmt.Errorf("failed to read from world state: %v", err)
	}

	return recordJSON != nil, nil
}

// ClaimRequestExists returns true when claim request with given ID exists in world state
func (s *HealthInsureChainContract) ClaimRequestExists(ctx contractapi.TransactionContextInterface, claimID string) (bool, error) {
	claimJSON, err := ctx.GetStub().GetState(claimID)
	if err != nil {
		return false, fmt.Errorf("failed to read from world state: %v", err)
	}

	return claimJSON != nil, nil
}

// Helper functions for querying
func getQueryResultsForPatientRecords(ctx contractapi.TransactionContextInterface, queryString string) ([]*PatientRecord, error) {
	resultsIterator, err := ctx.GetStub().GetQueryResult(queryString)
	if err != nil {
		return nil, err
	}
	defer resultsIterator.Close()

	var records []*PatientRecord
	for resultsIterator.HasNext() {
		queryResponse, err := resultsIterator.Next()
		if err != nil {
			return nil, err
		}

		var record PatientRecord
		err = json.Unmarshal(queryResponse.Value, &record)
		if err != nil {
			return nil, err
		}
		records = append(records, &record)
	}

	return records, nil
}

func getQueryResultsForClaimRequests(ctx contractapi.TransactionContextInterface, queryString string) ([]*ClaimRequest, error) {
	resultsIterator, err := ctx.GetStub().GetQueryResult(queryString)
	if err != nil {
		return nil, err
	}
	defer resultsIterator.Close()

	var claims []*ClaimRequest
	for resultsIterator.HasNext() {
		queryResponse, err := resultsIterator.Next()
		if err != nil {
			return nil, err
		}

		var claim ClaimRequest
		err = json.Unmarshal(queryResponse.Value, &claim)
		if err != nil {
			return nil, err
		}
		claims = append(claims, &claim)
	}

	return claims, nil
}

func main() {
	healthInsureChainContract, err := contractapi.NewChaincode(&HealthInsureChainContract{})
	if err != nil {
		fmt.Printf("Error creating HealthInsureChainContract chaincode: %v", err)
		return
	}

	if err := healthInsureChainContract.Start(); err != nil {
		fmt.Printf("Error starting HealthInsureChainContract chaincode: %v", err)
	}
}
