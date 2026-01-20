import SwiftUI
import PDFKit

struct ClaimSubmissionGuideView: View {
    let flight: Flight
    let claimReference: String
    let onDismiss: () -> Void
    
    // Helper struct for sheet presentation
    struct DocumentPreview: Identifiable {
        let id = UUID()
        let url: URL
    }
    
    enum WrapperState {
        case processing
        case success
    }
    
    @State private var state: WrapperState = .processing
    @State private var processingStep = "Initializing Safe Connection..."
    @State private var isAnimating = false
    @State private var selectedDocument: DocumentPreview?
    @State private var progress: CGFloat = 0.0
    @State private var bankDetailsSetup = false
    
    // Computed URLs for the documents
    private var masterAuthURL: URL? {
        ClaimDocumentService.shared.getPDFURL(for: claimReference, type: .masterAuthorization)
    }
    
    private var complaintLetterURL: URL? {
        ClaimDocumentService.shared.getPDFURL(for: claimReference, type: .airlineComplaint)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                WorldMapBackground()
                
                if state == .processing {
                    ProcessingView(step: processingStep, progress: progress)
                        .transition(.opacity)
                } else {
                    SuccessView
                        .transition(.scale(scale: 0.9).combined(with: .opacity))
                }
            }
            .navigationBarHidden(true)
            .sheet(item: $selectedDocument) { doc in
                PDFPreviewViewer(url: doc.url)
            }
            .onAppear {
                startSimulation()
            }
        }
    }
    
    var SuccessView: some View {
        ScrollView {
            VStack(spacing: 30) {
                // Success Animation
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(PremiumTheme.goldStart.opacity(0.2))
                            .frame(width: 100, height: 100)
                            .scaleEffect(isAnimating ? 1.0 : 0.5)
                            .opacity(isAnimating ? 1.0 : 0.0)
                        
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(PremiumTheme.goldGradient)
                            .shadow(color: PremiumTheme.goldStart.opacity(0.5), radius: 10)
                            .scaleEffect(isAnimating ? 1.0 : 0.5)
                            .opacity(isAnimating ? 1.0 : 0.0)
                    }
                    
                    Text("Claim Sent!")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                    
                    Text("Ref: \(claimReference)")
                        .font(.subheadline)
                        .monospaced()
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(8)
                        .foregroundStyle(.white.opacity(0.8))
                }
                .padding(.top, 40)
                
                // Status Card
                VStack(spacing: 20) {
                    Text("We've handled it.")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(PremiumTheme.electricBlue)
                    
                    Text("The Flighty Compensation team has officially submitted your formal complaint to **\(flight.airline.name)** via our priority legal channel.")
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white.opacity(0.8))
                        .padding(.horizontal)
                    
                    Divider().background(Color.white.opacity(0.1))
                    
                    HStack(spacing: 12) {
                        Image(systemName: "envelope.fill")
                            .foregroundStyle(.green)
                        Text("Copy sent to your email")
                            .font(.subheadline)
                            .foregroundStyle(.white)
                    }
                }
                .padding(24)
                .glassCard(cornerRadius: 20)
                
                // Documents Summary
                VStack(alignment: .leading, spacing: 16) {
                    Text("Filed Documents")
                        .font(.headline)
                        .foregroundStyle(.white.opacity(0.7))
                        .padding(.leading)
                    
                    // Master Auth Row
                    GuideDocumentRow(title: "Master Authorization", icon: "signature") {
                        if let url = masterAuthURL {
                            selectedDocument = DocumentPreview(url: url)
                        }
                    }
                    
                    // Complaint Letter Row (if present)
                    GuideDocumentRow(title: "Airline Complaint Letter", icon: "doc.text.fill") {
                        if let url = complaintLetterURL {
                            selectedDocument = DocumentPreview(url: url)
                        } else {
                            // Fallback if not found (should be there)
                            if let url = masterAuthURL {
                                 selectedDocument = DocumentPreview(url: url)
                            }
                        }
                    }
                }
                .padding(.horizontal)
                
                // Payout Setup Card - Prompt user to add bank details early
                PayoutSetupPromptCard(claimReference: claimReference) {
                    bankDetailsSetup = true
                    HapticsManager.shared.notification(type: .success)
                }
                .padding(.horizontal)
                
                // Done Button
                GradientButton(
                    title: "Done",
                    icon: "checkmark",
                    gradient: PremiumTheme.primaryGradient,
                    action: {
                        onDismiss()
                    }
                )
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .shadow(color: PremiumTheme.electricBlue.opacity(0.4), radius: 10, x: 0, y: 5)
            }
        }
    }
    
    func startSimulation() {
        // Steps: 0.0 -> 1.0 (3 seconds total)
        
        // Step 1
        withAnimation { progress = 0.1 }
        processingStep = "Encrypting documents..."
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation { progress = 0.4 }
            processingStep = "Connecting to secure server..."
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation { progress = 0.7 }
            processingStep = "Submitting claim to \(flight.airline.name)..."
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
            withAnimation { progress = 1.0 }
            processingStep = "Finalizing..."
            
            // Success
            withAnimation(.spring()) {
                state = .success
            }
            
            // Trigger animation inside success view
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
                    isAnimating = true
                }
                HapticsManager.shared.notification(type: .success)
            }
        }
    }
}

struct ProcessingView: View {
    let step: String
    let progress: CGFloat
    
    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: 6)
                    .frame(width: 70, height: 70)
                
                Circle()
                    .trim(from: 0, to: 0.75)
                    .stroke(PremiumTheme.electricBlue, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .frame(width: 70, height: 70)
                    .rotationEffect(.degrees(360))
                    .animation(Animation.linear(duration: 1).repeatForever(autoreverses: false), value: UUID())
            }
            
            VStack(spacing: 8) {
                Text(step)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                    .transition(.opacity)
                    .id(step)
                
                ProgressView(value: progress)
                    .progressViewStyle(LinearProgressViewStyle(tint: PremiumTheme.goldStart))
                    .frame(width: 180)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 28)
        .frame(maxWidth: 280)
        .glassCard(cornerRadius: 20)
    }
}

struct GuideDocumentRow: View {
    let title: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundStyle(PremiumTheme.electricBlue)
                    .frame(width: 40)
                
                Text(title)
                    .font(.body)
                    .foregroundStyle(.white)
                
                Spacer()
                
                Text("View")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(PremiumTheme.goldStart)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(PremiumTheme.goldStart.opacity(0.1))
                    .cornerRadius(6)
            }
            .padding()
            .glassCard(cornerRadius: 12)
        }
    }
}

struct PDFPreviewViewer: View {
    let url: URL
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            PDFKitView(url: url)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Close") {
                            dismiss()
                        }
                    }
                    ToolbarItem(placement: .navigationBarLeading) {
                        ShareLink(item: url) {
                            Image(systemName: "square.and.arrow.up")
                        }
                    }
                }
        }
    }
}

struct PDFKitView: UIViewRepresentable {
    let url: URL
    
    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        return pdfView
    }
    
    func updateUIView(_ pdfView: PDFView, context: Context) {
        if let document = PDFDocument(url: url) {
            pdfView.document = document
        }
    }
}
