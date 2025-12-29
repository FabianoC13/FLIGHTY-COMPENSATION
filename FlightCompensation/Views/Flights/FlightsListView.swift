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
                // Background
                WorldMapBackground()
                
                contentView
                
                // Floating Action Button
                floatingActionButton
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Reset App") {
                        HapticsManager.shared.notification(type: .warning)
                        UserProfileService.shared.clearProfile()
                    }
                    .font(.caption)
                    .foregroundStyle(.red.opacity(0.8))
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { 
                        HapticsManager.shared.impact(style: .light)
                        showAddFlight = true 
                    }) {
                        Image(systemName: "plus")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(.white)
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
                FlightDetailView(viewModel: makeDetailViewModel(for: flight))
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
        .toolbarColorScheme(.dark, for: .navigationBar) // Force dark appearance (white text) for this view only
    }
    
    @ViewBuilder
    private var contentView: some View {
        if viewModel.flights.isEmpty {
            EmptyStateView(onAddFlight: { showAddFlight = true })
        } else {
            flightList
        }
    }
    
    private var flightList: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 20) {
                // Custom Gradient Header
                Text("Your Flights")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(PremiumTheme.primaryGradient)
                    .padding(.horizontal, 20)
                    .padding(.top, 10) // Space below inline nav bar buttons
                
                ForEach(viewModel.flights) { flight in
                    FlightCardView(flight: flight) {
                        HapticsManager.shared.selection()
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            selectedFlight = flight
                        }
                    }
                }
            }
            .padding(.bottom, 80) // Add padding for FAB
            .padding(.top, 60) // Clear transparent inline Nav Bar
        }
        .scrollContentBackground(.hidden)
        .refreshable {
            HapticsManager.shared.impact(style: .medium)
            await refreshFlights()
            HapticsManager.shared.notification(type: .success)
        }
    }
    
    private var floatingActionButton: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Menu {
                    Button(action: { 
                        HapticsManager.shared.selection()
                        showAddFlight = true 
                    }) {
                        Label("Add Flight", systemImage: "plus")
                    }
                    Button(action: {
                        HapticsManager.shared.selection()
                        showAddFlight = true
                    }) {
                        Label("Import from Wallet", systemImage: "creditcard")
                    }
                    Button(action: {
                        HapticsManager.shared.selection()
                        showAddFlight = true
                    }) {
                        Label("Scan Ticket", systemImage: "qrcode.viewfinder")
                    }
                } label: {
                    Circle()
                        .fill(PremiumTheme.primaryGradient)
                        .frame(width: 64, height: 64)
                        .shadow(color: PremiumTheme.electricBlue.opacity(0.4), radius: 10, x: 0, y: 5)
                        .overlay(
                            Image(systemName: "plus")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                        )
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                }
                .simultaneousGesture(TapGesture().onEnded {
                    HapticsManager.shared.impact(style: .medium)
                })
                .padding()
            }
        }
    }
    
    private func makeDetailViewModel(for flight: Flight) -> FlightDetailViewModel {
        let detailViewModel = FlightDetailViewModel(
            flight: flight,
            flightTrackingService: AppDependencies().flightTrackingService,
            eligibilityService: AppDependencies().eligibilityService
        )
        // Wire up persistence callback
        detailViewModel.onFlightUpdate = { updatedFlight in
            viewModel.updateFlight(updatedFlight)
        }
        return detailViewModel
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
        VStack(spacing: 30) {
            Image(systemName: "airplane")
                .font(.system(size: 80))
                .foregroundStyle(PremiumTheme.electricBlue.opacity(0.6))
                .shadow(color: PremiumTheme.electricBlue.opacity(0.3), radius: 20)
            
            VStack(spacing: 12) {
                Text("No flights yet")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                
                Text("Add your first flight to start tracking compensation eligibility")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            GradientButton(
                title: "Add Flight",
                icon: "plus",
                gradient: PremiumTheme.primaryGradient,
                action: onAddFlight
            )
            .padding(.horizontal, 60)
        }
        .padding(40)
        .glassCard(cornerRadius: 30)
        .padding(20)
    }
}

