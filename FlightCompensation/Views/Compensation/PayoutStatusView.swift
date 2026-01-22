import SwiftUI

/// View showing the current payout status for a claim
struct PayoutStatusView: View {
    let claimId: UUID
    let claimReference: String
    let compensationAmount: Decimal
    
    @StateObject private var viewModel: PayoutStatusViewModel
    @State private var showPayoutDetails: Bool = false
    
    init(claimId: UUID, customerId: UUID, claimReference: String, compensationAmount: Decimal) {
        self.claimId = claimId
        self.claimReference = claimReference
        self.compensationAmount = compensationAmount
        _viewModel = StateObject(wrappedValue: PayoutStatusViewModel(claimId: claimId, customerId: customerId))
    }
    
    var body: some View {
        VStack(spacing: 16) {
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 200)
            } else if viewModel.recipient == nil {
                // No payout details yet
                noBankDetailsCard
            } else if let payout = viewModel.payout {
                // Payout exists - show status
                payoutStatusCard(payout: payout)
            } else {
                // Has recipient but no payout yet (awaiting AESA)
                awaitingFundsCard
            }
        }
        .sheet(isPresented: $showPayoutDetails) {
            PayoutDetailsView(
                claimId: claimId,
                customerId: viewModel.customerId,
                compensationAmount: compensationAmount
            ) { savedRecipient in
                viewModel.recipient = savedRecipient
            }
        }
        .task {
            await viewModel.loadData()
        }
        .refreshable {
            await viewModel.loadData()
        }
    }
    
    // MARK: - Cards
    
    private var noBankDetailsCard: some View {
        VStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.2))
                    .frame(width: 64, height: 64)
                
                Image(systemName: "creditcard.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.orange)
            }
            
            // Text
            VStack(spacing: 4) {
                Text("Add Payment Details")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text("Enter your bank details to receive your €\(NSDecimalNumber(decimal: compensationAmount).stringValue) compensation")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
            
            // Button
            Button {
                showPayoutDetails = true
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Bank Details")
                }
                .font(.headline)
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    LinearGradient(colors: [.yellow, .orange], startPoint: .leading, endPoint: .trailing)
                )
                .cornerRadius(12)
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
    }
    
    private var awaitingFundsCard: some View {
        VStack(spacing: 16) {
            // Status Icon
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 64, height: 64)
                
                Image(systemName: "clock.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.blue)
            }
            
            // Status Text
            VStack(spacing: 4) {
                Text("Awaiting AESA Settlement")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text("Your bank details are saved. Payment will be processed within 48 hours of receiving funds from AESA.")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
            
            // Bank Details Summary
            if let recipient = viewModel.recipient {
                bankDetailsSummary(recipient: recipient)
            }
            
            // Edit Button
            Button {
                showPayoutDetails = true
            } label: {
                HStack {
                    Image(systemName: "pencil")
                    Text("Edit Payment Details")
                }
                .font(.subheadline)
                .foregroundColor(.blue)
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
    }
    
    private func payoutStatusCard(payout: Payout) -> some View {
        VStack(spacing: 16) {
            // Status Icon
            ZStack {
                Circle()
                    .fill(statusColor(payout.status).opacity(0.2))
                    .frame(width: 64, height: 64)
                
                Image(systemName: payout.status.icon)
                    .font(.system(size: 28))
                    .foregroundColor(statusColor(payout.status))
            }
            
            // Amount
            Text("€\(NSDecimalNumber(decimal: payout.amountEUR).stringValue)")
                .font(.system(size: 32, weight: .bold))
                .foregroundStyle(
                    payout.status == .settled
                        ? LinearGradient(colors: [.green, .mint], startPoint: .leading, endPoint: .trailing)
                        : LinearGradient(colors: [.white], startPoint: .leading, endPoint: .trailing)
                )
            
            // Status Text
            VStack(spacing: 4) {
                Text(payout.status.displayText)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text(statusDescription(payout))
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
            
            // Timeline
            payoutTimeline(payout: payout)
            
            // Bank Details Summary
            if let recipient = viewModel.recipient {
                bankDetailsSummary(recipient: recipient)
            }
            
            // Action Buttons
            if payout.status == .failed {
                VStack(spacing: 12) {
                    if let reason = payout.failureReason {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                            Text(reason)
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                    }
                    
                    HStack(spacing: 12) {
                        Button {
                            showPayoutDetails = true
                        } label: {
                            HStack {
                                Image(systemName: "pencil")
                                Text("Update Details")
                            }
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(12)
                        }
                        
                        Button {
                            Task {
                                await viewModel.retryPayout()
                            }
                        } label: {
                            HStack {
                                if viewModel.isRetrying {
                                    ProgressView()
                                        .tint(.black)
                                } else {
                                    Image(systemName: "arrow.clockwise")
                                    Text("Retry")
                                }
                            }
                            .font(.subheadline)
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.orange)
                            .cornerRadius(12)
                        }
                        .disabled(viewModel.isRetrying)
                    }
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
    }
    
    private func bankDetailsSummary(recipient: PayoutRecipient) -> some View {
        HStack {
            Image(systemName: "building.columns")
                .foregroundColor(.gray)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(recipient.accountHolderName ?? "\(recipient.firstName) \(recipient.lastName)")
                    .font(.subheadline)
                    .foregroundColor(.white)
                
                Text(recipient.maskedIBAN ?? "Bank account")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Text(countryFlag(recipient.country))
                .font(.title2)
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
    
    private func payoutTimeline(payout: Payout) -> some View {
        VStack(spacing: 0) {
            // Created
            timelineRow(
                icon: "plus.circle",
                title: "Payout Created",
                date: payout.createdAt,
                isCompleted: true,
                isLast: false
            )
            
            // Queued
            timelineRow(
                icon: "list.bullet",
                title: "Queued for Processing",
                date: payout.queuedAt,
                isCompleted: payout.queuedAt != nil,
                isLast: false
            )
            
            // Sent
            timelineRow(
                icon: "paperplane.fill",
                title: "Payment Sent",
                date: payout.sentAt,
                isCompleted: payout.sentAt != nil,
                isLast: false
            )
            
            // Settled
            timelineRow(
                icon: "checkmark.circle.fill",
                title: "Payment Received",
                date: payout.settledAt,
                isCompleted: payout.settledAt != nil,
                isLast: true
            )
        }
        .padding()
        .background(Color.white.opacity(0.03))
        .cornerRadius(12)
    }
    
    private func timelineRow(icon: String, title: String, date: Date?, isCompleted: Bool, isLast: Bool) -> some View {
        HStack(alignment: .top, spacing: 12) {
            // Icon and line
            VStack(spacing: 0) {
                ZStack {
                    Circle()
                        .fill(isCompleted ? Color.green : Color.gray.opacity(0.3))
                        .frame(width: 24, height: 24)
                    
                    Image(systemName: isCompleted ? "checkmark" : icon)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(isCompleted ? .white : .gray)
                }
                
                if !isLast {
                    Rectangle()
                        .fill(isCompleted ? Color.green.opacity(0.5) : Color.gray.opacity(0.2))
                        .frame(width: 2, height: 32)
                }
            }
            
            // Text
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(isCompleted ? .white : .gray)
                
                if let date = date {
                    Text(formatDate(date))
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
        }
    }
    
    // MARK: - Helpers
    
    private func statusColor(_ status: PayoutStatus) -> Color {
        switch status {
        case .pending, .queued: return .orange
        case .processing, .sent: return .blue
        case .settled: return .green
        case .failed, .cancelled: return .red
        }
    }
    
    private func statusDescription(_ payout: Payout) -> String {
        switch payout.status {
        case .pending:
            return "Waiting for AESA to settle your claim."
        case .queued:
            return "Your payment is in the queue and will be processed shortly."
        case .processing:
            return "Your payment is being processed by our payment provider."
        case .sent:
            return "Payment has been sent to your bank. It should arrive within 1-3 business days."
        case .settled:
            return "Payment has been deposited into your account."
        case .failed:
            return "There was an issue with your payment. Please check your bank details."
        case .cancelled:
            return "This payment was cancelled."
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func countryFlag(_ code: String) -> String {
        let base: UInt32 = 127397
        var flag = ""
        for scalar in code.uppercased().unicodeScalars {
            if let unicode = UnicodeScalar(base + scalar.value) {
                flag.append(String(unicode))
            }
        }
        return flag
    }
}

// MARK: - ViewModel

@MainActor
final class PayoutStatusViewModel: ObservableObject {
    let claimId: UUID
    let customerId: UUID
    
    @Published var recipient: PayoutRecipient?
    @Published var payout: Payout?
    @Published var isLoading: Bool = false
    @Published var isRetrying: Bool = false
    @Published var error: String?
    
    private let payoutService = PayoutService.shared
    
    init(claimId: UUID, customerId: UUID) {
        self.claimId = claimId
        self.customerId = customerId
    }
    
    func loadData() async {
        isLoading = true
        
        do {
            recipient = try await payoutService.getRecipient(forClaimId: claimId)
            payout = try await payoutService.getPayout(forClaimId: claimId)
        } catch {
            self.error = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func retryPayout() async {
        guard let payout = payout else { return }
        
        isRetrying = true
        
        do {
            self.payout = try await payoutService.retryPayout(payoutId: payout.id)
        } catch {
            self.error = error.localizedDescription
        }
        
        isRetrying = false
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        
        ScrollView {
            PayoutStatusView(
                claimId: UUID(),
                customerId: UUID(),
                claimReference: "AESA-2026-1234",
                compensationAmount: 400
            )
            .padding()
        }
    }
}
