import Foundation

@MainActor
final class CompensationViewModel: ObservableObject {
    @Published var eligibility: CompensationEligibility
    @Published var isStartingClaim: Bool = false
    
    init(eligibility: CompensationEligibility) {
        self.eligibility = eligibility
    }
    
    func startClaim() {
        isStartingClaim = true
        // In a real app, this would navigate to claim process
        // For now, just a placeholder
        Task {
            try? await Task.sleep(nanoseconds: 500_000_000)
            isStartingClaim = false
        }
    }
}


