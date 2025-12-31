import Foundation
import SwiftUI
import Combine

enum ClaimStep: Int, CaseIterable {
    case passengerDetails = 0
    case claimTypeSelection
    case evidenceUpload
    case representationSignature
    case review
    
    var title: String {
        switch self {
        case .passengerDetails: return "Passenger Details"
        case .claimTypeSelection: return "Situation"
        case .evidenceUpload: return "Documents"
        case .representationSignature: return "Representation"
        case .review: return "Review & Submit"
        }
    }
}

enum ClaimType {
    case airline
    case aesa
}

@MainActor
final class ClaimViewModel: ObservableObject {
    @Published var currentStep: ClaimStep = .passengerDetails
    @Published var claimRequest: ClaimRequest
    @Published var isSubmitting: Bool = false
    @Published var submissionError: String?
    @Published var isSuccess: Bool = false
    @Published var claimReference: String?
    
    // New: Claim Type Selection
    @Published var claimType: ClaimType?
    
    // UI Helpers
    @Published var canMoveToNext: Bool = false
    
    // Signature
    @Published var signatureStrokeImage: UIImage?
    
    // Flight Data
    let flight: Flight
    
    // Dependencies
    private let pdfService = PDFService.shared
    private let submissionService: SubmissionServiceProtocol
    
    init(flight: Flight, submissionService: SubmissionServiceProtocol = MockSubmissionService()) {
        self.flight = flight
        self.submissionService = submissionService
        var initialRequest = ClaimRequest(flightId: flight.id.uuidString)
        
        // Auto-fill from UserProfile if available
        if let profile = UserProfileService.shared.userProfile {
            initialRequest.passengerDetails.firstName = profile.firstName
            initialRequest.passengerDetails.lastName = profile.lastName
            initialRequest.passengerDetails.email = profile.email
            initialRequest.passengerDetails.phoneNumber = profile.phoneNumber
            initialRequest.passengerDetails.documentType = profile.documentType
            initialRequest.passengerDetails.documentNumber = profile.documentNumber
            initialRequest.passengerDetails.address = profile.address
            
            // Auto-fill signature if available
            if let signatureData = profile.signatureData {
                initialRequest.representationAuth = RepresentationAuth(
                    signatureImage: signatureData,
                    signedDate: Date(),
                    signedLocation: "Pre-signed from Profile" // Simplified for now
                )
                
                // We also need to set the UI image for the ViewModel state if we want to show it.
                // However, 'signatureStrokeImage' is a UIImage.
                if let image = UIImage(data: signatureData) {
                    self.signatureStrokeImage = image
                }
            }
        }
        
        self.claimRequest = initialRequest
        
        // Skip Passenger Step if already onboarded and profile is valid
        if UserProfileService.shared.hasOnboarded && initialRequest.passengerDetails.isValid {
            self.currentStep = .claimTypeSelection
        } else {
            self.currentStep = .passengerDetails
        }
        
        setupValidation()
        validateCurrentStep()
    }
    
    private func setupValidation() {
        // In a real app, we might use Combine pipelines to auto-update 'canMoveToNext'
        // For simplicity, we'll check on appear/change
    }
    
    func selectClaimType(_ type: ClaimType) {
        self.claimType = type
        validateCurrentStep()
    }
    
    func validateCurrentStep() {
        switch currentStep {
        case .passengerDetails:
            canMoveToNext = claimRequest.passengerDetails.isValid
        case .claimTypeSelection:
            canMoveToNext = claimType != nil
        case .evidenceUpload:
            canMoveToNext = claimRequest.evidence.isComplete
        case .representationSignature:
            canMoveToNext = signatureStrokeImage != nil
        case .review:
            canMoveToNext = true
        }
    }
    
    func nextStep() {
        validateCurrentStep()
        guard canMoveToNext else { return }
        
        if let next = ClaimStep(rawValue: currentStep.rawValue + 1) {
            currentStep = next
            validateCurrentStep() // Re-validate for the new step
        }
    }
    
    func previousStep() {
        if let prev = ClaimStep(rawValue: currentStep.rawValue - 1) {
            currentStep = prev
            validateCurrentStep()
        }
    }
    
    func saveSignature(_ image: UIImage) {
        self.signatureStrokeImage = image
        if let data = image.pngData() {
            self.claimRequest.representationAuth = RepresentationAuth(
                signatureImage: data,
                signedDate: Date(),
                signedLocation: "In App" // Could get from CoreLocation
            )
        }
        validateCurrentStep()
    }
    
    func submitClaim() async {
        isSubmitting = true
        submissionError = nil
        
        // Generate PDF
        try? await Task.sleep(nanoseconds: 500_000_000) // Small UI delay for smoothness
        
        // Generate PDF
        guard let signatureImage = signatureStrokeImage,
              let userProfile = UserProfileService.shared.userProfile else {
            submissionError = "Missing profile or signature information."
            isSubmitting = false
            return
        }
        
        do {
            // 1. Generate Master Authorization (Always Required)
            let masterPdfData = try pdfService.generateMasterAuthorizationPDF(
                userProfile: userProfile,
                flight: flight,
                signature: signatureImage
            )
            
            // 2. Generate Airline Complaint (If applicable)
            var airlineLetterData: Data?
            if claimType == .airline {
                airlineLetterData = try pdfService.generateAirlineComplaintPDF(
                    userProfile: userProfile,
                    flight: flight
                )
            }
            
            // Submit to Backend (Master Doc is the legal definition of the claim)
            let response = try await submissionService.submitClaim(request: claimRequest, pdfData: masterPdfData)
            
            // Success condition
            isSubmitting = false
            isSuccess = true
            claimReference = response.claimReference
            
            // Save secondary document if exists
            if let letterData = airlineLetterData {
                _ = ClaimDocumentService.shared.savePDF(data: letterData, claimReference: response.claimReference, type: .airlineComplaint)
            }
            
            // For the Airline Flow, the "Claim Status" should be set to .airlineClaimSubmitted
            // For AESA Flow, it should be .aesaSubmitted.
            // This logic happens in the callbacks in `ClaimFlowView` or `FlightDetailViewModel`, but we can hint it here.
            
        } catch {
            submissionError = "Submission failed: \(error.localizedDescription)"
            isSubmitting = false
        }
    }
}
