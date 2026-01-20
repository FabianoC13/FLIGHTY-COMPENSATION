//
//  PayoutIntegrationView.swift
//  FlightCompensation
//
//  Card component that prompts users to enter their bank details
//  to receive their compensation faster.
//

import SwiftUI

/// A card view prompting users to add bank details for faster payout
/// Used in the ClaimSubmissionGuideView after successful claim submission
struct PayoutSetupPromptCard: View {
    let claimReference: String
    let onSetupComplete: () -> Void
    
    @State private var showPayoutDetails = false
    @State private var hasSetupBankDetails = false
    
    // Generate stable UUIDs from claim reference for consistency
    private var claimId: UUID {
        // Create deterministic UUID from claim reference string
        let data = claimReference.data(using: .utf8) ?? Data()
        var bytes = [UInt8](repeating: 0, count: 16)
        data.withUnsafeBytes { dataBytes in
            for (index, byte) in dataBytes.prefix(16).enumerated() {
                bytes[index] = byte
            }
        }
        return UUID(uuid: (bytes[0], bytes[1], bytes[2], bytes[3], bytes[4], bytes[5], bytes[6], bytes[7],
                          bytes[8], bytes[9], bytes[10], bytes[11], bytes[12], bytes[13], bytes[14], bytes[15]))
    }
    
    private var customerId: UUID {
        // For now, generate from claim reference - in production, get from user session
        let data = ("user-" + claimReference).data(using: .utf8) ?? Data()
        var bytes = [UInt8](repeating: 0, count: 16)
        data.withUnsafeBytes { dataBytes in
            for (index, byte) in dataBytes.prefix(16).enumerated() {
                bytes[index] = byte
            }
        }
        return UUID(uuid: (bytes[0], bytes[1], bytes[2], bytes[3], bytes[4], bytes[5], bytes[6], bytes[7],
                          bytes[8], bytes[9], bytes[10], bytes[11], bytes[12], bytes[13], bytes[14], bytes[15]))
    }
    
    // Default compensation amount (can be passed in future versions)
    private let compensationAmount: Decimal = 400
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(PremiumTheme.goldStart.opacity(0.2))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: "banknote.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(PremiumTheme.goldGradient)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Get Paid Faster")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text("Add bank details now")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                if hasSetupBankDetails {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.green)
                } else {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            
            if !hasSetupBankDetails {
                Text("Set up your bank details now so we can send your compensation as soon as the airline approves your claim—no delays!")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
                    .fixedSize(horizontal: false, vertical: true)
                
                Button {
                    showPayoutDetails = true
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Add Bank Details")
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(PremiumTheme.electricBlue.opacity(0.2))
                    .foregroundColor(PremiumTheme.electricBlue)
                    .cornerRadius(10)
                }
            } else {
                Text("Your bank details are saved. We'll send your compensation within 48 hours of receiving the funds.")
                    .font(.caption)
                    .foregroundColor(.green.opacity(0.8))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(20)
        .glassCard(cornerRadius: 16)
        .sheet(isPresented: $showPayoutDetails) {
            PayoutDetailsView(
                claimId: claimId,
                customerId: customerId,
                compensationAmount: compensationAmount
            ) { savedRecipient in
                hasSetupBankDetails = true
                showPayoutDetails = false
                onSetupComplete()
            }
        }
        .onAppear {
            checkExistingBankDetails()
        }
    }
    
    private func checkExistingBankDetails() {
        // Check if recipient already exists for this claim
        Task {
            if let recipient = try? await PayoutService.shared.getRecipient(forClaimId: claimId) {
                await MainActor.run {
                    hasSetupBankDetails = recipient.status == .verified
                }
            }
        }
    }
}

/// Card shown when waiting for AESA funds
struct AwaitingFundsCard: View {
    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(PremiumTheme.electricBlue.opacity(0.2))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: "hourglass")
                        .font(.system(size: 20))
                        .foregroundStyle(PremiumTheme.electricBlue)
                        .symbolEffect(.pulse)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Awaiting Funds")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text("Bank details ready ✓")
                        .font(.subheadline)
                        .foregroundColor(.green)
                }
                
                Spacer()
            }
            
            Text("Your bank details are saved. Once the airline transfers your compensation to us, we'll forward it to your account within 48 hours.")
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(20)
        .glassCard(cornerRadius: 16)
    }
}

// MARK: - ClaimStatus Extensions

extension ClaimStatus {
    var isApproved: Bool {
        switch self {
        case .approved, .paid:
            return true
        default:
            return false
        }
    }
    
    var statusDescription: String {
        switch self {
        case .notStarted:
            return "Your claim is being prepared."
        case .airlineClaimSubmitted:
            return "Your complaint has been sent to the airline. They have 6 weeks to respond."
        case .airlineRejected:
            return "The airline rejected your claim. We're escalating to AESA."
        case .aesaSubmitted:
            return "Your claim has been escalated to AESA (Spanish Aviation Authority). They typically respond within 90 days."
        case .approved:
            return "Great news! Your compensation has been approved. Payment is being processed."
        case .paid:
            return "Your compensation has been received and transferred to your account."
        }
    }
}

#if DEBUG
struct PayoutIntegrationView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 20) {
                PayoutSetupPromptCard(
                    claimReference: "FC-2024-001"
                ) {
                    print("Setup complete")
                }
                
                AwaitingFundsCard()
            }
            .padding()
        }
    }
}
#endif
