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
                            case .claimTypeSelection:
                                ClaimTypeSelectionView(viewModel: viewModel)
                            case .evidenceUpload:
                                DocumentUploadView(viewModel: viewModel)
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
                                        let isAuthenticated = await BiometricService.shared.authenticateUser(reason: "Verify your identity to submit the claim")
                                        if isAuthenticated {
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
            .alert("Success", isPresented: $viewModel.isSuccess) {
                Button("Done") {
                    HapticsManager.shared.notification(type: .success)
                    if let ref = viewModel.claimReference {
                        let status: ClaimStatus = (viewModel.claimType == .airline) ? .airlineClaimSubmitted : .aesaSubmitted
                        onClaimSuccess(ref, status)
                    }
                    dismiss()
                }
            } message: {
                if let ref = viewModel.claimReference {
                    if viewModel.claimType == .airline {
                        Text("Claim Reference: \(ref)\n\nWe have generated the COMPLAINT LETTER for the airline and your MASTER AUTHORIZATION. Please enable the 'Airline First' flow to proceed.")
                    } else {
                        Text("Claim Reference: \(ref)\n\nMaster Authorization generated. We will now proceed with the formal submission to AESA.")
                    }
                } else {
                    Text("Your claim has been prepared.")
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
                    LabeledContentRow(label: "Name", value: "\(viewModel.claimRequest.passengerDetails.firstName) \(viewModel.claimRequest.passengerDetails.lastName)")
                    Divider().background(Color.white.opacity(0.1))
                    LabeledContentRow(label: "Document", value: "\(viewModel.claimRequest.passengerDetails.documentType.rawValue) - \(viewModel.claimRequest.passengerDetails.documentNumber)")
                }
            }
            
            ReviewSection(title: "Documents") {
                VStack(alignment: .leading, spacing: 8) {
                    LabeledContentRow(label: "Boarding Pass", value: "Uploaded", valueColor: .green)
                    Divider().background(Color.white.opacity(0.1))
                    LabeledContentRow(label: "ID/Passport", value: "Uploaded", valueColor: .green)
                }
            }
            
            ReviewSection(title: "Representation") {
                HStack {
                    if viewModel.claimRequest.representationAuth != nil {
                        Label("Digitally Signed", systemImage: "signature")
                            .foregroundStyle(PremiumTheme.goldStart)
                    } else {
                        Label("Missing Signature", systemImage: "exclamationmark.triangle")
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
            
            Text("AESA requires you to contact the airline first. If they denied your request or didn't answer in 30 days, we can escalate.")
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
