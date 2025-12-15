---
name: Flight Compensation iOS App
overview: Build a premium iOS app for flight delay compensation with Flighty-inspired UI, using SwiftUI, MVVM architecture, and protocol-based services with mock data. The app will include a complete eligibility rules engine (EU261/UK261), flight tracking services, and multiple flight input methods (Wallet, scanning, manual entry).
todos:
  - id: setup-project
    content: Create Xcode project structure with proper folder organization and Info.plist configuration
    status: completed
  - id: create-models
    content: Implement all core data models (Flight, Airport, Airline, FlightStatus, DelayEvent, CompensationEligibility) as immutable, Codable structs
    status: completed
    dependencies:
      - setup-project
  - id: services-protocols
    content: Create service protocols (FlightTrackingService, EligibilityService, WalletImportService) with proper async/await signatures
    status: completed
    dependencies:
      - create-models
  - id: eligibility-engine
    content: Implement EU261EligibilityService with full rules engine (distance calculations, delay thresholds, jurisdiction checks, plain-language outputs)
    status: completed
    dependencies:
      - services-protocols
  - id: mock-services
    content: Create mock implementations for all services (MockFlightTrackingService, MockWalletImportService) with realistic test data
    status: completed
    dependencies:
      - services-protocols
  - id: dependency-injection
    content: Create AppDependencies container for dependency injection and service wiring
    status: completed
    dependencies:
      - mock-services
      - eligibility-engine
  - id: viewmodels
    content: Implement all ViewModels (FlightsListViewModel, FlightDetailViewModel, AddFlightViewModel, CompensationViewModel) with proper @Published properties and business logic
    status: completed
    dependencies:
      - dependency-injection
  - id: home-screen
    content: Build FlightsListView and FlightCardView with clean design, status indicators, and smooth animations
    status: completed
    dependencies:
      - viewmodels
  - id: detail-screen
    content: Create FlightDetailView with timeline layout, live status, delay info, and eligibility display
    status: completed
    dependencies:
      - home-screen
  - id: add-flight-flow
    content: Build AddFlightView modal with three input methods (Wallet, Scan, Manual) and corresponding sub-views
    status: completed
    dependencies:
      - viewmodels
  - id: compensation-screen
    content: Create CompensationView with large amount display, plain-language explanation, and clear CTAs
    status: completed
    dependencies:
      - detail-screen
  - id: navigation
    content: Wire up NavigationStack-based navigation with proper deep linking and modal presentations
    status: completed
    dependencies:
      - home-screen
      - detail-screen
      - add-flight-flow
      - compensation-screen
  - id: animations-polish
    content: Add subtle animations (matchedGeometryEffect, smooth transitions), generous spacing, rounded cards, and visual polish throughout
    status: completed
    dependencies:
      - navigation
  - id: error-handling
    content: Implement user-friendly error handling, loading states, and graceful degradation for edge cases
    status: completed
    dependencies:
      - animations-polish
---

# Flight Compensation iOS App - Implementation Plan

## Architecture Overview

The app follows MVVM architecture with clear separation of concerns:

- **Models**: Immutable, Codable data structures
- **Services**: Protocol-based, injectable services (flight tracking, eligibility, wallet parsing)
- **ViewModels**: Business logic coordinators that bridge Views and Services
- **Views**: Declarative SwiftUI screens with minimal logic

### Project Structure

```
FlightCompensation/
├── App/
│   ├── FlightCompensationApp.swift        # App entry point
│   └── AppDependencies.swift              # Dependency injection container
├── Models/
│   ├── Flight.swift
│   ├── Airport.swift
│   ├── Airline.swift
│   ├── FlightStatus.swift
│   ├── DelayEvent.swift
│   └── CompensationEligibility.swift
├── Services/
│   ├── FlightTrackingService.swift        # Protocol
│   ├── MockFlightTrackingService.swift    # Mock implementation
│   ├── EligibilityService.swift           # Protocol
│   ├── EU261EligibilityService.swift      # Rules engine implementation
│   ├── WalletImportService.swift          # Protocol
│   └── MockWalletImportService.swift      # Mock implementation
├── ViewModels/
│   ├── FlightsListViewModel.swift
│   ├── FlightDetailViewModel.swift
│   ├── AddFlightViewModel.swift
│   └── CompensationViewModel.swift
├── Views/
│   ├── Flights/
│   │   ├── FlightsListView.swift          # Home screen
│   │   ├── FlightCardView.swift           # Flight list item
│   │   └── FlightDetailView.swift         # Flight detail screen
│   ├── AddFlight/
│   │   ├── AddFlightView.swift            # Modal sheet entry point
│   │   ├── WalletImportView.swift
│   │   ├── TicketScanView.swift
│   │   └── ManualEntryView.swift
│   └── Compensation/
│       └── CompensationView.swift         # Eligibility display
└── Utilities/
    ├── Extensions/
    └── Constants.swift
```

## Implementation Steps

### 1. Core Data Models

Create immutable, Codable models in `Models/`:

**Flight.swift**: Core flight data model

- Properties: id, flightNumber, airline, departureAirport, arrivalAirport, scheduledDeparture, scheduledArrival, status, currentStatus, delayEvents
- Include computed properties for display (e.g., route string)

**Airport.swift**: Airport information

- Properties: code, name, city, country

**Airline.swift**: Airline information

- Properties: code, name, logoURL

**FlightStatus.swift**: Enum for flight status

- Cases: scheduled, onTime, delayed, cancelled, departed, arrived

**DelayEvent.swift**: Delay/cancellation information

- Properties: type (delay/cancellation), duration, actualTime, reason

**CompensationEligibility.swift**: Eligibility result

- Properties: isEligible, amount, currency, reason (plain language), confidence

### 2. Services Layer (Protocol-Based)

Create service protocols with mock implementations:

**FlightTrackingService.swift** (Protocol)

- `func trackFlight(_ flight: Flight) async throws -> FlightStatus`
- `func getFlightStatus(_ flightNumber: String, date: Date) async throws -> FlightStatus`

**MockFlightTrackingService.swift**

- Simulates flight status updates with realistic delays

**EligibilityService.swift** (Protocol)

- `func checkEligibility(for flight: Flight, delayEvent: DelayEvent) async -> CompensationEligibility`

**EU261EligibilityService.swift** (Implementation)

- Rules engine implementing EU261/UK261:
                                                                                                                                - Distance-based thresholds (≤1500km: €250, >1500km intra-EU: €400, >3500km: €600)
                                                                                                                                - Delay duration thresholds (3+ hours arrival delay)
                                                                                                                                - Jurisdiction checks (EU/UK airlines or EU/UK destinations)
                                                                                                                                - Outputs plain-language eligibility reasons

**WalletImportService.swift** (Protocol)

- `func importFlightFromWallet() async throws -> Flight?`
- Structure for WalletKit integration (implementation stub)

**MockWalletImportService.swift**

- Returns mock flight data simulating wallet import

### 3. ViewModels (MVVM)

**FlightsListViewModel.swift**

- `@Published var flights: [Flight]`
- `func loadFlights()`
- `func deleteFlight(_ flight: Flight)`
- Observes flight status updates

**FlightDetailViewModel.swift**

- `@Published var flight: Flight?`
- `@Published var eligibility: CompensationEligibility?`
- `func trackFlight()`
- `func checkEligibility()`
- Coordinates tracking and eligibility services

**AddFlightViewModel.swift**

- `@Published var selectedMethod: AddFlightMethod`
- `func addFlight(_ flight: Flight)`
- Handles different input methods

**CompensationViewModel.swift**

- `@Published var eligibility: CompensationEligibility`
- `func startClaim()`

### 4. Views (SwiftUI)

**FlightsListView.swift** (Home Screen)

- Clean list using `LazyVStack`
- Flight cards with airline logo, route, status indicators
- Color-coded status (green/amber/red)
- Pull-to-refresh
- NavigationStack-based navigation

**FlightCardView.swift**

- Rounded card design with subtle shadow
- Airline logo/image
- Route display (MAD → CDG)
- Status badge with color
- `matchedGeometryEffect` for smooth transitions

**FlightDetailView.swift**

- Timeline-style layout
- Sections: Flight info, Live status, Delay info, Eligibility
- Smooth scroll animations
- Large, clear compensation amount display when eligible

**AddFlightView.swift** (Modal Sheet)

- Three-button layout:
                                                                                                                                - "Import from Wallet" (primary, prominent)
                                                                                                                                - "Scan ticket"
                                                                                                                                - "Enter flight number"
- Guides user to fastest option

**WalletImportView.swift** / **TicketScanView.swift** / **ManualEntryView.swift**

- Each handles its specific input method
- Minimal, focused UI
- Auto-suggestions where possible

**CompensationView.swift**

- Large, clear text: "You may be entitled to €400"
- 1-2 line explanation
- Primary CTA: "Start claim"
- Secondary: "Save for later"

### 5. Dependency Injection

**AppDependencies.swift**

- Centralized dependency container
- Provides mock services for development
- Easy to swap for real implementations later

### 6. Eligibility Rules Engine

**EU261EligibilityService.swift** implementation:

```
1. Check jurisdiction (EU/UK airline or route)
2. Calculate distance (airport-to-airport)
3. Check delay duration (actual vs scheduled arrival)
4. Apply rules:
   - ≤1500km, 3+ hour delay → €250
   - >1500km intra-EU, 3+ hour delay → €400
   - >3500km, 3+ hour delay → €400
   - >3500km, 4+ hour delay → €600
5. Generate plain-language reason
6. Return CompensationEligibility
```

### 7. Navigation & Routing

- Use `NavigationStack` (iOS 17+)
- Deep linking structure for flight details
- Modal presentation for Add Flight flow
- Smooth transitions between screens

### 8. UI/UX Polish

- Generous spacing (16-24pt padding)
- Rounded corners (12-16pt radius)
- Subtle shadows
- Smooth animations (fade, slide)
- Light mode first (dark mode structure prepared)
- No clutter, no dense text

### 9. Error Handling

- User-friendly error messages
- "We're checking" states for uncertain eligibility
- Never blame the user
- Graceful degradation for missing data

## Technical Decisions

1. **iOS 17+ only**: Use latest SwiftUI features (NavigationStack, modern async/await patterns)
2. **Protocol-oriented services**: Easy to mock and test, swap implementations
3. **Immutable models**: Thread-safe, predictable state
4. **MVVM strict**: No business logic in Views
5. **Mock-first**: Develop with mock data, swap real services later
6. **Plain language**: All user-facing text avoids legal jargon

## Development Order

1. Set up Xcode project structure and folders
2. Create core Models
3. Create Service protocols and mock implementations
4. Build Eligibility rules engine
5. Create ViewModels
6. Build Views (starting with FlightsList, then Detail, then Add Flight)
7. Wire up navigation
8. Add animations and polish
9. Error handling and edge cases

## Files to Create

**Core Files (Priority Order):**

1. `App/FlightCompensationApp.swift`
2. `App/AppDependencies.swift`
3. `Models/*.swift` (all model files)
4. `Services/*.swift` (protocols and implementations)
5. `ViewModels/*.swift`
6. `Views/Flights/FlightsListView.swift`
7. `Views/Flights/FlightCardView.swift`
8. `Views/Flights/FlightDetailView.swift`
9. `Views/AddFlight/AddFlightView.swift`
10. `Views/Compensation/CompensationView.swift`
11. `Utilities/Constants.swift`

## Next Steps After Plan Approval

Once approved, I will:

1. Create the Xcode project structure
2. Implement all models with proper Codable conformance
3. Build the services layer with mock data
4. Implement the eligibility rules engine
5. Create all ViewModels following MVVM principles
6. Build all SwiftUI views with Flighty-inspired design
7. Wire everything together with proper navigation
8. Add smooth animations and polish

The result will be a production-ready foundation that can easily integrate real APIs and services when ready.