import Foundation

enum AddFlightMethod: String, CaseIterable {
    case wallet = "Import from Wallet"
    case scan = "Scan ticket"
    case manual = "Enter flight number"
}

@MainActor
final class AddFlightViewModel: ObservableObject {
    @Published var selectedMethod: AddFlightMethod?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let walletImportService: WalletImportService
    private var onFlightAdded: (Flight) -> Void
    
    init(
        walletImportService: WalletImportService,
        onFlightAdded: @escaping (Flight) -> Void
    ) {
        self.walletImportService = walletImportService
        self.onFlightAdded = onFlightAdded
    }
    
    func selectMethod(_ method: AddFlightMethod) {
        selectedMethod = method
    }
    
    func importFromWallet() async {
        isLoading = true
        errorMessage = nil
        
        do {
            if let flight = try await walletImportService.importFlightFromWallet() {
                onFlightAdded(flight)
                isLoading = false
            } else {
                errorMessage = "No flight found in Wallet."
                isLoading = false
            }
        } catch {
            errorMessage = "Unable to import flight from Wallet. Please try another method."
            isLoading = false
        }
    }
    
    func addFlightManually(_ flight: Flight) {
        onFlightAdded(flight)
    }
    
    func addFlightFromScan(_ flight: Flight) {
        onFlightAdded(flight)
    }
}


