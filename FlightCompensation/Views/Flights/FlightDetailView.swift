import SwiftUI

struct FlightDetailView: View {
    @StateObject private var viewModel: FlightDetailViewModel
    @State private var showCompensation = false
    
    init(viewModel: FlightDetailViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        ScrollView {
            if let flight = viewModel.flight {
                VStack(alignment: .leading, spacing: AppConstants.largeSpacing) {
                    // Flight Info Card
                    FlightInfoCard(flight: flight)
                    
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
                    
                    // Eligibility Card - Always show when available
                    if let eligibility = viewModel.eligibility {
                        EligibilityCard(eligibility: eligibility, showViewDetails: eligibility.isEligible) {
                            if eligibility.isEligible {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    showCompensation = true
                                }
                            }
                        }
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
        .task {
            if let flight = viewModel.flight {
                viewModel.loadFlight(flight)
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
                            .foregroundColor(.accentColor)
                    }
                    Spacer()
                }
                
                Text(eligibility.reason)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                
                if showViewDetails {
                    Button(action: onViewCompensation) {
                        Text("View Details")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.accentColor)
                            .cornerRadius(AppConstants.cardCornerRadius)
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

