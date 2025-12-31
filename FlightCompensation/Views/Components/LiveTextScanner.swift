import SwiftUI
import VisionKit

@MainActor
struct LiveTextScanner: UIViewControllerRepresentable {
    let onFlightCodeDetected: (String) -> Void
    let onCancel: () -> Void
    
    func makeUIViewController(context: Context) -> DataScannerViewController {
        let scanner = DataScannerViewController(
            recognizedDataTypes: [.text()],
            qualityLevel: .balanced,
            recognizesMultipleItems: true, // Allow multiple so we don't get stuck on big titles
            isHighFrameRateTrackingEnabled: true,
            isPinchToZoomEnabled: true,
            isGuidanceEnabled: true,
            isHighlightingEnabled: true
        )
        scanner.delegate = context.coordinator
        return scanner
    }
    
    func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) {
        if !uiViewController.isScanning {
            try? uiViewController.startScanning()
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, DataScannerViewControllerDelegate {
        let parent: LiveTextScanner
        var isProcessing = false
        
        init(_ parent: LiveTextScanner) {
            self.parent = parent
        }
        
        func dataScanner(_ dataScanner: DataScannerViewController, didTapOn item: RecognizedItem) {
            processItem(item, isTap: true)
        }
        
        func dataScanner(_ dataScanner: DataScannerViewController, didAdd addedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            // Disable auto-capture to prevent false positives (like GATE 16 -> AT16).
            // User must tap the highlighted text.
        }
        
        private func processItem(_ item: RecognizedItem, isTap: Bool = false) {
            // We only process if tapped, or if we decide to re-enable auto-capture later
            guard isTap, !isProcessing else { return }
            
            if case .text(let text) = item {
                if let flightCode = extractFlightCode(from: text.transcript) {
                    isProcessing = true
                    
                    // Feedback
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                    
                    parent.onFlightCodeDetected(flightCode)
                } else if isTap {
                    // Feedback for invalid tap
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.error)
                }
            }
        }
        
        private func extractFlightCode(from text: String) -> String? {
            // Normalize: Uppercase and allow varying spaces
            let raw = text.uppercased()
            
            // Regex: strict IATA format.
            // Start of word (\b), 2 alphanumerics (Airline), optional space, 1-4 digits (Flight Num), End of word (\b).
            // Example: "BA123", "AA 45".
            // Excludes "MAN20" (3 chars) or date times like "12:30".
            let pattern = "\\b[A-Z0-9]{2}\\s?\\d{1,4}\\b"
            
            guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
            let nsString = raw as NSString
            let results = regex.matches(in: raw, options: [], range: NSRange(location: 0, length: nsString.length))
            
            for result in results {
                let match = nsString.substring(with: result.range)
                // Filter out common false positives (dates, times, seat numbers)
                // 1. Must have at least one letter (to avoid "2024" or "12:30")
                let hasLetters = match.rangeOfCharacter(from: .letters) != nil
                // 2. Must have at least one digit
                let hasDigits = match.rangeOfCharacter(from: .decimalDigits) != nil
                
                if hasLetters && hasDigits {
                    // Normalize by removing spaces: "IB 3450" -> "IB3450"
                    return match.replacingOccurrences(of: " ", with: "")
                }
            }
            
            return nil
        }
    }
}
