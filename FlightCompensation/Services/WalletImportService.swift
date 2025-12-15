import Foundation

protocol WalletImportService {
    func importFlightFromWallet() async throws -> Flight?
}


