import SwiftUI
import MessageUI

struct FlightDetailView: View {
    @StateObject private var viewModel: FlightDetailViewModel
    @State private var showCompensation = false
    @State private var showClaimFlow = false
    
    @State private var showShareSheet = false
    @State private var documentURL: URL?
    
    @State private var showWalletPass = false
    
    // Email State
    @State private var showMailView = false
    @State private var mailResult: Result<MFMailComposeResult, Error>?
    @State private var showMailError = false
    
    init(viewModel: FlightDetailViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        ScrollView {
            if let flight = viewModel.flight {
                VStack(alignment: .leading, spacing: AppConstants.largeSpacing) {
                    // Map (show if airports have coordinates) - MOVED TO TOP for premium feel
                    if let originCoord = flight.departureAirport.coordinate, let destCoord = flight.arrivalAirport.coordinate {
                        FlightMapView(originCoordinate: originCoord, destinationCoordinate: destCoord, planePosition: viewModel.planePosition)
                            .frame(height: 220)
                            .cornerRadius(12)
                            .shadow(radius: 5)
                            // Remove padding to make it full width or edge-to-edge if desired, but keep consistent for now
                    }

                    // Flight Info Card
                    FlightInfoCard(flight: flight)
                    
                    // Wallet Pass Card (New)
                    WalletCard {
                        self.showWalletPass = true
                    }
                    
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
                                    self.showShareSheet = true
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
        .navigationTitle("Flight Details")
        .navigationBarTitleDisplayMode(.inline)
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
        .sheet(isPresented: $showWalletPass) {
            if let flight = viewModel.flight {
                ZStack {
                    Color(UIColor.systemGroupedBackground).ignoresSafeArea()
                    WalletPassView(flight: flight)
                        .padding()
                }
                .presentationDetents([.fraction(0.85)])
                .presentationDragIndicator(.visible)
            }
        }
        .task {
            if let flight = viewModel.flight {
                viewModel.loadFlight(flight)
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let url = documentURL {
                ShareSheet(activityItems: [url])
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
                        
                        // 2. Update local view model
                        viewModel.loadFlight(updated)
                        
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
    }
}

struct WalletCard: View {
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                Image(systemName: "wallet.pass.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.white)
                    .frame(width: 48, height: 48)
                    .background(LinearGradient(colors: [.black, .gray], startPoint: .top, endPoint: .bottom))
                    .cornerRadius(12)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Boarding Pass")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text("View Digital Pass")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
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
                Spacer()
                StatusBadge(status: flight.currentStatus)
            }
            
            Divider()
            
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
                .foregroundColor(.secondary)
        }
        .padding(AppConstants.cardPadding)
        .background(Color(.systemBackground))
        .cornerRadius(AppConstants.cardCornerRadius)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
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
                    .foregroundColor(.secondary)
                Text(airport.displayName)
                    .font(.system(size: 16, weight: .medium))
            }
            
            Spacer()
            
            Text(time, style: .time)
                .font(.system(size: 16, weight: .semibold))
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
                Spacer()
                if isLoading {
                    ProgressView()
                } else {
                    Button(action: onRefresh) {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(.accentColor)
                    }
                }
            }
            
            Text("Status: \(flight.currentStatus.displayName)")
                .font(.system(size: 16))
        }
        .padding(AppConstants.cardPadding)
        .background(Color(.systemBackground))
        .cornerRadius(AppConstants.cardCornerRadius)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

struct DelayInfoCard: View {
    let delayEvent: DelayEvent
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppConstants.spacing) {
            Text("Delay Information")
                .font(.system(size: 18, weight: .semibold))
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Duration:")
                        .foregroundColor(.secondary)
                    Text(delayEvent.formattedDuration)
                        .font(.system(size: 16, weight: .medium))
                }
                
                if let reason = delayEvent.reason {
                    Text(reason)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(AppConstants.cardPadding)
        .background(Color(.systemBackground))
        .cornerRadius(AppConstants.cardCornerRadius)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
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
            
            if eligibility.isEligible {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("You may be entitled to")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                        Text(eligibility.formattedAmount)
                            .font(.system(size: 32, weight: .bold))
                            .foregroundStyle(.primary)
                    }
                    Spacer()
                }
                
                Text(eligibility.reason)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                
                if showViewDetails {
                    VStack(spacing: 12) {
                        Button(action: onViewCompensation) {
                            Text("View Details")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.accentColor)
                                .cornerRadius(AppConstants.cardCornerRadius)
                        }
                        
                        Button(action: onFileClaim) {
                            Text("File AESA Claim")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.accentColor)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.accentColor.opacity(0.1))
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
                    }
                    
                    Text(eligibility.reason)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(AppConstants.cardPadding)
        .background(Color(.systemBackground))
        .cornerRadius(AppConstants.cardCornerRadius)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

struct CheckingEligibilityCard: View {
    var body: some View {
        HStack {
            ProgressView()
            Text("Checking eligibility...")
                .font(.system(size: 16))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(AppConstants.cardPadding)
        .background(Color(.systemBackground))
        .cornerRadius(AppConstants.cardCornerRadius)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
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
            
            // Master Auth Row
            if let url = masterAuthURL {
                DocumentRow(
                    title: "Master Authorization",
                    subtitle: "Ref: \(claimReference)",
                    icon: "doc.text.fill",
                    onTap: { onViewDocument(url) }
                )
            }
            
            // Airline Complaint Row
            if let url = complaintLetterURL {
                if masterAuthURL != nil {
                    Divider()
                }
                DocumentRow(
                    title: "Airline Complaint Letter",
                    subtitle: "Tap to email airline",
                    icon: "paperplane.fill", // Changed icon to indicate sending
                    onTap: { onSendComplaint(url) }
                )
            }
            
            Text("These documents are stored on your device.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(AppConstants.cardPadding)
        .background(Color(.systemBackground))
        .cornerRadius(AppConstants.cardCornerRadius)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

struct DocumentRow: View {
    let title: String
    let subtitle: String
    let icon: String
    let onTap: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.accentColor)
                .frame(width: 40, height: 40)
                .background(Color.accentColor.opacity(0.1))
                .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: onTap) {
                Image(systemName: "square.and.arrow.up")
                    .foregroundColor(.accentColor)
            }
        }
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(8)
    }
}
