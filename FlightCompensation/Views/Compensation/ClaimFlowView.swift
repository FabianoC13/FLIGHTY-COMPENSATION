import SwiftUI

struct ClaimFlowView: View {
    let flight: Flight
    @StateObject private var viewModel: ClaimViewModel
    @Environment(\.dismiss) private var dismiss
    
    let onClaimSuccess: (String, ClaimStatus) -> Void
    
    init(flight: Flight, onClaimSuccess: @escaping (String, ClaimStatus) -> Void) {
        self.flight = flight
        self.onClaimSuccess = onClaimSuccess
        _viewModel = StateObject(wrappedValue: ClaimViewModel(flight: flight))
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                WorldMapBackground()
                
                VStack {
                    // Progress Indicator
                    ClaimProgressView(currentStep: viewModel.currentStep)
                        .padding(.vertical)
                    
                    // Content
                    ScrollView {
                        VStack(spacing: 24) {
                            switch viewModel.currentStep {
                            case .passengerDetails:
                                PassengerFormView(viewModel: viewModel)
                            case .disruptionDetails:
                                DisruptionDetailsView(viewModel: viewModel)
                            case .claimTypeSelection:
                                ClaimTypeSelectionView(viewModel: viewModel)
                            case .evidenceUpload:
                                DocumentUploadView(viewModel: viewModel)
                            case .agreements:
                                ClaimAgreementsView(viewModel: viewModel)
                            case .representationSignature:
                                RepresentationSignatureView(viewModel: viewModel)
                            case .review:
                                ClaimReviewView(viewModel: viewModel)
                            }
                        }
                        .padding(.horizontal)
                    }
                    .scrollIndicators(.hidden)
                    
                    // Navigation Buttons
                    HStack(spacing: 20) {
                        if viewModel.currentStep != .passengerDetails {
                            Button {
                                withAnimation {
                                    viewModel.previousStep()
                                }
                            } label: {
                                Image(systemName: "arrow.left")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(width: 56, height: 56)
                                    .glassCard(cornerRadius: 16)
                            }
                        }
                        
                            if viewModel.currentStep == .review {
                            GradientButton(
                                title: viewModel.isSubmitting ? "Submitting..." : "Submit Claim",
                                icon: "checkmark.shield.fill",
                                gradient: PremiumTheme.goldGradient,
                                action: {
                                    HapticsManager.shared.impact(style: .heavy)
                                    Task {
                                        let isAuthenticated = await BiometricService.shared.authenticateUser(reason: "Confirm your identity to sign and submit the claim")
                                        if !isAuthenticated {
                                            viewModel.submissionError = "We couldn't confirm your identity. Please try again."
                                            HapticsManager.shared.notification(type: .error)
                                        } else {
                                            await viewModel.submitClaim()
                                            if viewModel.isSuccess {
                                                HapticsManager.shared.notification(type: .success)
                                            } else {
                                                HapticsManager.shared.notification(type: .error)
                                            }
                                        }
                                    }
                                },
                                isDisabled: viewModel.isSubmitting
                            )
                        } else {
                            GradientButton(
                                title: "Next Step",
                                icon: "arrow.right",
                                gradient: PremiumTheme.primaryGradient,
                                action: {
                                    HapticsManager.shared.impact(style: .light)
                                    withAnimation {
                                        viewModel.nextStep()
                                    }
                                },
                                isDisabled: !viewModel.canMoveToNext
                            )
                        }
                    }
                    .padding(24)
                }
            }
            .navigationTitle(viewModel.currentStep.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundStyle(.white)
                            .padding(8)
                            .background(Circle().fill(.ultraThinMaterial))
                    }
                }
            }
            .alert("Couldn't submit the claim", isPresented: Binding(
                get: { viewModel.submissionError != nil },
                set: { if !$0 { viewModel.submissionError = nil } }
            )) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.submissionError ?? "")
            }
            .fullScreenCover(isPresented: $viewModel.isSuccess) {
                if let ref = viewModel.claimReference {
                    ClaimSubmissionGuideView(
                        flight: flight,
                        claimReference: ref,
                        onDismiss: {
                            HapticsManager.shared.notification(type: .success)
                            let status: ClaimStatus = (viewModel.claimType == .airline) ? .airlineClaimSubmitted : .aesaSubmitted
                            onClaimSuccess(ref, status)
                            dismiss()
                        }
                    )
                }
            }
        }
    }
}

struct ClaimProgressView: View {
    let currentStep: ClaimStep
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(ClaimStep.allCases, id: \.self) { step in
                Rectangle()
                    .fill(step.rawValue <= currentStep.rawValue ? PremiumTheme.electricBlue : Color.white.opacity(0.1))
                    .frame(height: 4)
                    .cornerRadius(2)
                    .shadow(color: step.rawValue <= currentStep.rawValue ? PremiumTheme.electricBlue : .clear, radius: 4)
            }
        }
        .padding(.horizontal, 24)
    }
}

struct ClaimReviewView: View {
    @ObservedObject var viewModel: ClaimViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            ReviewSection(title: "Flight") {
                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.flight.displayFlightNumber)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                    Text(viewModel.flight.route)
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
            
            ReviewSection(title: "Passenger") {
                VStack(alignment: .leading, spacing: 8) {
                    LabeledContentRow(label: "Name", value: viewModel.claimRequest.passengerDetails.travellerFullName)
                    if viewModel.claimRequest.passengerDetails.minor != nil {
                        Divider().background(Color.white.opacity(0.1))
                        LabeledContentRow(label: "Signed by", value: viewModel.claimRequest.passengerDetails.signerFullName)
                    }
                    Divider().background(Color.white.opacity(0.1))
                    LabeledContentRow(label: "Booking", value: viewModel.claimRequest.passengerDetails.bookingReference.uppercased())
                    Divider().background(Color.white.opacity(0.1))
                    LabeledContentRow(label: "Document", value: "\(viewModel.claimRequest.passengerDetails.documentType.rawValue) - \(viewModel.claimRequest.passengerDetails.documentNumber)")
                }
            }

            ReviewSection(title: "Compensation") {
                VStack(alignment: .leading, spacing: 8) {
                    LabeledContentRow(label: "Claim", value: viewModel.amountText, valueColor: PremiumTheme.goldStart)
                    Divider().background(Color.white.opacity(0.1))
                    LabeledContentRow(label: "You receive", value: viewModel.netPayoutText)
                    Divider().background(Color.white.opacity(0.1))
                    LabeledContentRow(label: "Reference", value: viewModel.pendingReference)
                }
            }
            
            ReviewSection(title: "Documents") {
                VStack(alignment: .leading, spacing: 8) {
                    let evidence = viewModel.claimRequest.evidence
                    LabeledContentRow(label: "Boarding Pass", value: evidence.boardingPassImage != nil ? "Added" : "Not added",
                                      valueColor: evidence.boardingPassImage != nil ? .green : .white.opacity(0.5))
                    Divider().background(Color.white.opacity(0.1))
                    LabeledContentRow(label: "Booking confirmation", value: evidence.bookingConfirmationImage != nil ? "Added" : "Not added",
                                      valueColor: evidence.bookingConfirmationImage != nil ? .green : .white.opacity(0.5))
                    Divider().background(Color.white.opacity(0.1))
                    LabeledContentRow(label: "ID/Passport", value: evidence.identityDocumentImage != nil ? "Added" : "Not added",
                                      valueColor: evidence.identityDocumentImage != nil ? .green : .white.opacity(0.5))
                }
            }
            
            ReviewSection(title: "Authorisation") {
                HStack {
                    if viewModel.signatureStrokeImage != nil && viewModel.claimRequest.consents.allRequiredAccepted {
                        Label("Accepted and signed", systemImage: "signature")
                            .foregroundStyle(PremiumTheme.goldStart)
                    } else {
                        Label("Missing signature", systemImage: "exclamationmark.triangle")
                            .foregroundStyle(.red)
                    }
                    Spacer()
                }
            }
        }
    }
}

struct ReviewSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundStyle(PremiumTheme.electricBlue)
                .padding(.leading, 4)
            
            VStack(alignment: .leading, spacing: 12) {
                content
            }
            .padding(16)
            .glassCard(cornerRadius: 16)
        }
    }
}

struct LabeledContentRow: View {
    let label: String
    let value: String
    var valueColor: Color = .white
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.white.opacity(0.6))
            Spacer()
            Text(value)
                .bold()
                .foregroundStyle(valueColor)
        }
    }
}


// MARK: - Claim Type Selection
struct ClaimTypeSelectionView: View {
    @ObservedObject var viewModel: ClaimViewModel
    
    var body: some View {
        VStack(spacing: 24) {
            Text("What's the situation?")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .padding(.top)
            
            Text("Airlines must be contacted first. If they rejected your claim or didn't answer within a month, we escalate it to AESA, the Spanish enforcement body.")
                .font(.body)
                .foregroundStyle(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            VStack(spacing: 16) {
                // Option 1: File with Airline
                SelectionCard(
                    title: "First Contact",
                    description: "I haven't submitted a formal claim yet.",
                    icon: "airplane.departure",
                    isSelected: viewModel.claimType == .airline,
                    onTap: { viewModel.selectClaimType(.airline) }
                )
                
                // Option 2: Airline Rejected
                SelectionCard(
                    title: "Appeal Rejection",
                    description: "I have proof they said NO (or ignored me).",
                    icon: "exclamationmark.shield.fill",
                    isSelected: viewModel.claimType == .aesa,
                    onTap: { viewModel.selectClaimType(.aesa) }
                )
            }
            .padding(.top, 20)
            
            Spacer()
        }
    }
}

struct SelectionCard: View {
    let title: String
    let description: String
    let icon: String
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundStyle(isSelected ? .white : PremiumTheme.electricBlue)
                    .frame(width: 50, height: 50)
                    .background(isSelected ? PremiumTheme.electricBlue.opacity(0.3) : .clear)
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(.white)
                    
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(PremiumTheme.goldStart)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? PremiumTheme.electricBlue.opacity(0.2) : Color.white.opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? PremiumTheme.electricBlue : Color.white.opacity(0.1), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}
