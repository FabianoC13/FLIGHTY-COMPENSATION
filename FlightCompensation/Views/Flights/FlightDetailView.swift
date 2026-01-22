import SwiftUI
import MessageUI
import PDFKit

struct FlightDetailView: View {
    @StateObject private var viewModel: FlightDetailViewModel
    @State private var showCompensation = false
    @State private var showClaimFlow = false
    
    @State private var showShareSheet = false
    @State private var showQuickLook = false
    @State private var documentURL: URL?
    
    
    @State private var showPayoutDetails = false
    
    // Email State
    @State private var showMailView = false
    @State private var mailResult: Result<MFMailComposeResult, Error>?
    @State private var showMailError = false
    
    init(viewModel: FlightDetailViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        ZStack {
            // Dark Background
            PremiumTheme.backgroundGradient
                .ignoresSafeArea()
            
            ScrollView {
                if let flight = viewModel.flight {
                    VStack(alignment: .leading, spacing: AppConstants.largeSpacing) {
                        // Map (show if airports have coordinates) - MOVED TO TOP for premium feel
                        if let originCoord = flight.departureAirport.coordinate, let destCoord = flight.arrivalAirport.coordinate {
                            FlightMapView(originCoordinate: originCoord, destinationCoordinate: destCoord, planePosition: viewModel.planePosition)
                                .frame(height: 220)
                                .cornerRadius(12)
                                .shadow(radius: 5)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                )
                        }

                        // Flight Info Card
                        FlightInfoCard(flight: flight)
                        
                        // Documents Card (New)
                        if let ref = flight.claimReference {
                            let masterUrl = ClaimDocumentService.shared.getPDFURL(for: ref, type: .masterAuthorization)
                            let complaintUrl = ClaimDocumentService.shared.getPDFURL(for: ref, type: .airlineComplaint)
                            
                            if masterUrl != nil || complaintUrl != nil {
                                DocumentsCard(
                                    claimReference: ref,
                                    masterAuthURL: masterUrl,
                                    complaintLetterURL: complaintUrl,
                                    onViewDocument: { url in
                                        self.documentURL = url
                                        self.showQuickLook = true
                                    },
                                    onSendComplaint: { url in
                                        if MFMailComposeViewController.canSendMail() {
                                            self.documentURL = url
                                            self.showMailView = true
                                        } else {
                                            self.showMailError = true
                                        }
                                    }
                                )
                            }
                            
                            // Payment Details Card - Show when claim is submitted
                            PaymentDetailsCard(
                                claimReference: ref,
                                claimStatus: flight.claimStatus,
                                onSetupPayment: {
                                    showPayoutDetails = true
                                }
                            )
                        }
                        
                        // Live Status Card
                        LiveStatusCard(
                            flight: flight,
                            isLoading: viewModel.isLoading,
                            onRefresh: { viewModel.trackFlight() }
                        )
                        
                        // Delay Info (if delayed)
                        if flight.hasActiveDelay, let delayEvent = flight.latestDelayEvent {
                            DelayInfoCard(delayEvent: delayEvent)
                        }

                        // Timeline (show all delay/cancel events)
                        FlightTimelineView(events: viewModel.timelineEvents)

                        // Eligibility Card - Always show when available
                        if let eligibility = viewModel.eligibility {
                            EligibilityCard(
                                eligibility: eligibility,
                                showViewDetails: eligibility.isEligible,
                                onViewCompensation: {
                                    if eligibility.isEligible {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                            showCompensation = true
                                        }
                                    }
                                },
                                onFileClaim: {
                                    showClaimFlow = true
                                }
                            )
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                        } else if viewModel.isCheckingEligibility {
                            CheckingEligibilityCard()
                            .transition(.opacity)
                        }
                    }
                    .padding(AppConstants.spacing)
                }
            }
        }
        .navigationTitle("Flight Details")
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(.dark)
        .animation(.easeInOut(duration: 0.3), value: viewModel.eligibility)
        .alert("Error", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK") {
                viewModel.errorMessage = nil
            }
        } message: {
            if let error = viewModel.errorMessage {
                Text(error)
            }
        }
        .sheet(isPresented: $showCompensation) {
            if let eligibility = viewModel.eligibility {
                CompensationView(
                    viewModel: CompensationViewModel(eligibility: eligibility)
                )
            }
        }

        .task {
            if let flight = viewModel.flight {
                // If flight has claim data, don't refresh to preserve documents
                let hasClaimData = flight.claimReference != nil
                viewModel.loadFlight(flight, skipRefresh: hasClaimData)
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let url = documentURL {
                ShareSheet(activityItems: [url])
            }
        }
        .sheet(isPresented: $showQuickLook) {
            if let url = documentURL {
                QuickLookPreview(url: url)
            }
        }
        .fullScreenCover(isPresented: $showClaimFlow) {
            if let flight = viewModel.flight {
                ClaimFlowView(
                    flight: flight,
                    onClaimSuccess: { ref, status in
                        // 1. Create updated flight
                        var updated = flight
                        updated.claimStatus = status
                        updated.claimReference = ref
                        
                        // 2. Update local view model (skip refresh to avoid re-tracking)
                        viewModel.loadFlight(updated, skipRefresh: true)
                        
                        // 3. Notify parent (List) so it persists
                        viewModel.onFlightUpdate?(updated)
                    }
                )
            }
        }
        .sheet(isPresented: $showMailView) {
            if let url = documentURL, let flight = viewModel.flight {
                MailView(
                    result: $mailResult,
                    recipients: [flight.flightNumber.lowercased() == "delay001" ? "fabianocalvaye@gmail.com" : flight.airline.claimEmail],
                    ccRecipients: ["claims@flightcompensation.app"],
                    subject: "Formal Complaint - Flight \(flight.displayFlightNumber)",
                    messageBody: """
                    To whom it may concern,
                    
                    Please find attached my formal complaint regarding flight \(flight.displayFlightNumber) on \(flight.scheduledDeparture.formatted(date: .abbreviated, time: .omitted)).
                    
                    I request that you process this claim in accordance with Regulation (EC) No 261/2004.
                    
                    Sincerely,
                    Passenger
                    """,
                    attachmentData: try? Data(contentsOf: url),
                    attachmentFileName: url.lastPathComponent
                )
            }
        }
        .alert("Email Unavailable", isPresented: $showMailError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("This device is not configured to send emails. Please check your Mail settings.")
        }
        .sheet(isPresented: $showPayoutDetails) {
            if let flight = viewModel.flight, let ref = flight.claimReference {
                PayoutDetailsView(
                    claimId: UUID(uuidString: ref) ?? flight.id,
                    customerId: UUID(),
                    compensationAmount: viewModel.eligibility?.amount ?? 400
                ) { _ in
                    showPayoutDetails = false
                }
            }
        }
    }
}



struct FlightInfoCard: View {
    let flight: Flight
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppConstants.spacing) {
            HStack {
                Text(flight.displayFlightNumber)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
                StatusBadge(status: flight.currentStatus)
            }
            
            Divider().background(Color.white.opacity(0.2))
            
            VStack(alignment: .leading, spacing: 12) {
                RouteRow(
                    airport: flight.departureAirport,
                    time: flight.scheduledDeparture,
                    label: "Departure"
                )
                
                RouteRow(
                    airport: flight.arrivalAirport,
                    time: flight.scheduledArrival,
                    label: "Arrival"
                )
            }
            
            Text(flight.airline.name)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.6))
        }
        .padding(AppConstants.cardPadding)
        .background(Material.ultraThin)
        .cornerRadius(AppConstants.cardCornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: AppConstants.cardCornerRadius)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

struct RouteRow: View {
    let airport: Airport
    let time: Date
    let label: String
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.6))
                Text(airport.displayName)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            Text(time, style: .time)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
        }
    }
}

struct LiveStatusCard: View {
    let flight: Flight
    let isLoading: Bool
    let onRefresh: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppConstants.spacing) {
            HStack {
                Text("Live Status")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                Spacer()
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Button(action: onRefresh) {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(PremiumTheme.electricBlue)
                    }
                }
            }
            
            Text("Status: \(flight.currentStatus.displayName)")
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.9))
        }
        .padding(AppConstants.cardPadding)
        .background(Material.ultraThin)
        .cornerRadius(AppConstants.cardCornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: AppConstants.cardCornerRadius)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

struct DelayInfoCard: View {
    let delayEvent: DelayEvent
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppConstants.spacing) {
            Text("Delay Information")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Duration:")
                        .foregroundColor(.white.opacity(0.6))
                    Text(delayEvent.formattedDuration)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                }
                
                if let reason = delayEvent.reason {
                    Text(reason)
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
        }
        .padding(AppConstants.cardPadding)
        .background(Material.ultraThin)
        .cornerRadius(AppConstants.cardCornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: AppConstants.cardCornerRadius)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

struct EligibilityCard: View {
    let eligibility: CompensationEligibility
    let showViewDetails: Bool
    let onViewCompensation: () -> Void
    let onFileClaim: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppConstants.spacing) {
            Text("Compensation Eligibility")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
            
            if eligibility.isEligible {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("You may be entitled to")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.6))
                        Text(eligibility.formattedAmount)
                            .font(.system(size: 32, weight: .bold))
                            .foregroundStyle(PremiumTheme.goldStart)
                    }
                    Spacer()
                }
                
                Text(eligibility.reason)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.6))
                
                if showViewDetails {
                    VStack(spacing: 12) {
                        Button(action: onViewCompensation) {
                            Text("View Details")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(PremiumTheme.electricBlue)
                                .cornerRadius(AppConstants.cardCornerRadius)
                        }
                        
                        Button(action: onFileClaim) {
                            Text("File AESA Claim")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(PremiumTheme.electricBlue)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(PremiumTheme.electricBlue.opacity(0.2))
                                .cornerRadius(AppConstants.cardCornerRadius)
                        }
                    }
                }
            } else {
                // Show "No delay" message but still display the card with information
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("No Delay Detected")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    
                    Text(eligibility.reason)
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
        }
        .padding(AppConstants.cardPadding)
        .background(Material.ultraThin)
        .cornerRadius(AppConstants.cardCornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: AppConstants.cardCornerRadius)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

struct CheckingEligibilityCard: View {
    var body: some View {
        HStack {
            ProgressView()
                .tint(.white)
            Text("Checking eligibility...")
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(AppConstants.cardPadding)
        .background(Material.ultraThin)
        .cornerRadius(AppConstants.cardCornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: AppConstants.cardCornerRadius)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}



struct DocumentsCard: View {
    let claimReference: String
    let masterAuthURL: URL?
    let complaintLetterURL: URL?
    let onViewDocument: (URL) -> Void
    let onSendComplaint: (URL) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppConstants.spacing) {
            Text("Claim Documents")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
            
            // Master Auth Row
            if let url = masterAuthURL {
                DocumentRow(
                    title: "Master Authorization",
                    subtitle: "Tap to view",
                    icon: "doc.text.fill",
                    onTap: { onViewDocument(url) }
                )
            }
            
            // Airline Complaint Row
            if let url = complaintLetterURL {
                if masterAuthURL != nil {
                    Divider().background(Color.white.opacity(0.2))
                }
                DocumentRow(
                    title: "Airline Complaint Letter",
                    subtitle: "Tap to view",
                    icon: "doc.text.fill",
                    onTap: { onViewDocument(url) }
                )
            }
            
            Text("These documents are stored on your device.")
                .font(.caption)
                .foregroundColor(.white.opacity(0.5))
        }
        .padding(AppConstants.cardPadding)
        .background(Material.ultraThin)
        .cornerRadius(AppConstants.cardCornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: AppConstants.cardCornerRadius)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

struct DocumentRow: View {
    let title: String
    let subtitle: String
    let icon: String
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(PremiumTheme.electricBlue)
                    .frame(width: 40, height: 40)
                    .background(PremiumTheme.electricBlue.opacity(0.15))
                    .cornerRadius(8)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.5))
            }
            .padding(12)
            .background(Color.black.opacity(0.2))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Payment Details Card

struct PaymentDetailsCard: View {
    let claimReference: String
    let claimStatus: ClaimStatus?
    let onSetupPayment: () -> Void
    
    private var paymentStatusText: String {
        // Check if we have saved payment details in UserDefaults
        if let _ = UserDefaults.standard.string(forKey: "payout_method_\(claimReference)") {
            return "Payment method saved"
        }
        return "No payment method set"
    }
    
    private var paymentStatusIcon: String {
        if let _ = UserDefaults.standard.string(forKey: "payout_method_\(claimReference)") {
            return "checkmark.circle.fill"
        }
        return "exclamationmark.circle.fill"
    }
    
    private var paymentStatusColor: Color {
        if let _ = UserDefaults.standard.string(forKey: "payout_method_\(claimReference)") {
            return .green
        }
        return .orange
    }
    
    private var buttonTitle: String {
        if let _ = UserDefaults.standard.string(forKey: "payout_method_\(claimReference)") {
            return "Edit Payment Method"
        }
        return "Set Up Payment"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppConstants.spacing) {
            HStack {
                Text("Payment Details")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
                
                HStack(spacing: 6) {
                    Image(systemName: paymentStatusIcon)
                        .foregroundColor(paymentStatusColor)
                    Text(paymentStatusText)
                        .font(.system(size: 12))
                        .foregroundColor(paymentStatusColor)
                }
            }
            
            Text("Set up how you want to receive your compensation once your claim is approved.")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.6))
                .fixedSize(horizontal: false, vertical: true)
            
            Button(action: onSetupPayment) {
                HStack {
                    Image(systemName: "creditcard.fill")
                        .font(.system(size: 16))
                    Text(buttonTitle)
                        .font(.system(size: 16, weight: .medium))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        colors: [PremiumTheme.electricBlue, PremiumTheme.electricBlue.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
            }
        }
        .padding(AppConstants.cardPadding)
        .background(Material.ultraThin)
        .cornerRadius(AppConstants.cardCornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: AppConstants.cardCornerRadius)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

// MARK: - PDF Preview

struct QuickLookPreview: View {
    let url: URL
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            PDFKitView(url: url)
                .navigationTitle("Document Preview")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Done") {
                            dismiss()
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        ShareLink(item: url) {
                            Image(systemName: "square.and.arrow.up")
                        }
                    }
                }
        }
        .preferredColorScheme(.dark)
    }
}
