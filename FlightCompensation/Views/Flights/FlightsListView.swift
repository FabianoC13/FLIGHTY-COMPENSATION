import SwiftUI

struct FlightsListView: View {
    @StateObject private var viewModel: FlightsListViewModel
    @State private var showAddFlight = false
    @State private var selectedFlight: Flight?
    
    init(viewModel: FlightsListViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                if viewModel.flights.isEmpty {
                    EmptyStateView(onAddFlight: { showAddFlight = true })
                } else {
                    ScrollView {
                        LazyVStack(spacing: AppConstants.spacing) {
                            ForEach(viewModel.flights) { flight in
                                FlightCardView(flight: flight) {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                        selectedFlight = flight
                                    }
                                }
                            }
                        }
                        .padding(AppConstants.spacing)
                    }
                    .refreshable {
                        await refreshFlights()
                    }
                }
            }
            .navigationTitle("Your Flights")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showAddFlight = true }) {
                        Image(systemName: "plus")
                            .font(.system(size: 18, weight: .medium))
                    }
                }
            }
            .sheet(isPresented: $showAddFlight) {
                AddFlightView(
                    viewModel: AddFlightViewModel(
                        walletImportService: AppDependencies().walletImportService,
                        onFlightAdded: { flight in
                            viewModel.addFlight(flight)
                            showAddFlight = false
                        }
                    )
                )
            }
            .navigationDestination(item: $selectedFlight) { flight in
                FlightDetailView(
                    viewModel: FlightDetailViewModel(
                        flight: flight,
                        flightTrackingService: AppDependencies().flightTrackingService,
                        eligibilityService: AppDependencies().eligibilityService
                    )
                )
            }
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
        }
    }
    
    private func refreshFlights() async {
        for flight in viewModel.flights {
            viewModel.refreshFlightStatus(flight)
        }
    }
}

struct EmptyStateView: View {
    let onAddFlight: () -> Void
    
    var body: some View {
        VStack(spacing: AppConstants.largeSpacing) {
            Image(systemName: "airplane")
                .font(.system(size: 64))
                .foregroundColor(.secondary)
            
            Text("No flights yet")
                .font(.system(size: 24, weight: .semibold))
            
            Text("Add your first flight to start tracking compensation eligibility")
                .font(.system(size: 16))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppConstants.largeSpacing)
            
            Button(action: onAddFlight) {
                Text("Add Flight")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.accentColor)
                    .cornerRadius(AppConstants.cardCornerRadius)
            }
            .padding(.horizontal, AppConstants.largeSpacing)
            .padding(.top, AppConstants.spacing)
        }
    }
}

