import SwiftUI

struct FlightsListView: View {
    @StateObject private var viewModel: FlightsListViewModel
    let authService: AuthenticationService
    @State private var showAddFlight = false
    @State private var showSettings = false
    @State private var selectedFlight: Flight?
    
    // Map style toggle
    @State private var isSatelliteMap: Bool = true
    
    // State for draggable sheet
    @State private var sheetState: SheetState = .half
    @GestureState private var dragTranslation: CGFloat = 0
    
    private enum SheetState {
        case hidden
        case half
        case full
        
        var heightRatio: CGFloat {
            switch self {
            case .hidden: return 0.15 // Just the header/handle visible (peek)
            case .half: return 0.55
            case .full: return 0.88
            }
        }
    }

    init(viewModel: FlightsListViewModel, authService: AuthenticationService) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.authService = authService
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
                    Button(action: {
                        HapticsManager.shared.impact(style: .light)
                        showSettings = true
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color(red: 0.15, green: 0.17, blue: 0.20))
                                .frame(width: 36, height: 36)
                            Image(systemName: "person.fill")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white.opacity(0.9))
                        }
                    }
                    .buttonStyle(.plain)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        HapticsManager.shared.selection()
                        isSatelliteMap.toggle()
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color(red: 0.15, green: 0.17, blue: 0.20))
                                .frame(width: 36, height: 36)
                            Image(systemName: isSatelliteMap ? "map.fill" : "globe.americas.fill")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white.opacity(0.9))
                        }
                    }
                    .buttonStyle(.plain)
                }

            }
            .sheet(isPresented: $showSettings) {
                SettingsProfileView(
                    authService: authService
                )
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
        .onAppear {
            viewModel.loadFlights()
        }
    }
    
    @ViewBuilder
    private var contentView: some View {
        flightList
    }
    
    private var flightList: some View {
        GeometryReader { geometry in
            let screenHeight = geometry.size.height
            // For empty state, don't allow hidden - minimum is half
            let minRatio: CGFloat = viewModel.flights.isEmpty ? 0.40 : sheetState.heightRatio
            let targetRatio = max(sheetState.heightRatio, viewModel.flights.isEmpty ? 0.40 : 0.15)
            let currentHeight = screenHeight * targetRatio - dragTranslation
            
            ZStack(alignment: .bottom) {
                // Full-screen Interactive Globe (Background)
                FlightsGlobeView(flights: viewModel.flights, isSatelliteView: $isSatelliteMap)
                    .ignoresSafeArea()
                
                // Floating Sheet (Overlay)
                VStack(alignment: .leading, spacing: 0) {
                    // Drag handle indicator
                    Capsule()
                        .fill(Color.white.opacity(0.3))
                        .frame(width: 40, height: 5)
                        .padding(.top, 10)
                        .frame(maxWidth: .infinity)
                    
                    if viewModel.flights.isEmpty {
                        // Educational Empty State
                        EmptyStateEducationalView(onAddFlight: {
                            showAddFlight = true
                        })
                    } else {
                        // Flight List Content
                        VStack(alignment: .leading, spacing: 0) {
                            // Header
                            HStack {
                                Text("Your Flights")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundStyle(.white)
                                Spacer()
                                Text("\(viewModel.flights.count) flight\(viewModel.flights.count == 1 ? "" : "s")")
                                    .font(.custom("HelveticaNeue-Medium", size: 12))
                                    .foregroundStyle(.white.opacity(0.5))
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 12)
                            .padding(.bottom, 12)
                            
                            // Scrollable boarding passes
                            ScrollView {
                                LazyVStack(spacing: 20) {
                                    ForEach(viewModel.flights) { flight in
                                        ClassicBoardingPass(
                                            flight: flight,
                                            onTap: {
                                                HapticsManager.shared.selection()
                                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                                    selectedFlight = flight
                                                }
                                            },
                                            onDelete: {
                                                viewModel.deleteFlight(flight)
                                            }
                                        )
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.bottom, 100) // Space for FAB
                            }
                            .scrollContentBackground(.hidden)
                            .refreshable {
                                HapticsManager.shared.impact(style: .medium)
                                await refreshFlights()
                                HapticsManager.shared.notification(type: .success)
                            }
                            // Allow scrolling only if fully expanded or content is large
                            .scrollDisabled(sheetState == .hidden || sheetState == .half && viewModel.flights.count < 3) 
                        }
                    }
                }
                .frame(height: max(currentHeight, 150)) // Minimum 150pt to prevent collapse
                .background(
                    RoundedRectangle(cornerRadius: 30)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.06, green: 0.07, blue: 0.12).opacity(0.95),
                                    Color(red: 0.03, green: 0.03, blue: 0.06).opacity(0.98)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                )
                .clipShape(RoundedRectangle(cornerRadius: 30))
                .shadow(color: .black.opacity(0.5), radius: 20, x: 0, y: -10)
                .padding(.horizontal, 12) // Side borders to reveal globe
                .gesture(
                    DragGesture(minimumDistance: 10)
                        .updating($dragTranslation) { value, state, _ in
                            state = value.translation.height
                        }
                        .onEnded { value in
                            let dragThreshold: CGFloat = 50
                            let translation = value.translation.height
                            
                            // Calculate projected end state
                            var nextState = sheetState
                            
                            if translation < -dragThreshold {
                                // Dragged UP
                                switch sheetState {
                                case .hidden: nextState = .half
                                case .half: nextState = .full
                                case .full: nextState = .full
                                }
                            } else if translation > dragThreshold {
                                // Dragged DOWN
                                switch sheetState {
                                case .hidden: nextState = .hidden
                                case .half: 
                                    // For empty state, don't go to hidden
                                    nextState = viewModel.flights.isEmpty ? .half : .hidden
                                case .full: nextState = .half
                                }
                            }
                            
                            withAnimation(.interactiveSpring(response: 0.35, dampingFraction: 0.85)) {
                                sheetState = nextState
                            }
                        }
                )
            }
        }
        .ignoresSafeArea(edges: .top)
    }
    
    private var floatingActionButton: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button(action: {
                    HapticsManager.shared.impact(style: .medium)
                    showAddFlight = true
                }) {
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
                .padding([.bottom, .trailing], 30)
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

