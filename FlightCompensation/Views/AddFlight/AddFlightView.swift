import SwiftUI

struct AddFlightView: View {
    @StateObject private var viewModel: AddFlightViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showManualEntry = false
    @State private var showTicketScan = false
    
    init(viewModel: AddFlightViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Dark gradient background
                LinearGradient(
                    colors: [
                        Color(red: 0.06, green: 0.07, blue: 0.14),
                        Color(red: 0.02, green: 0.02, blue: 0.05)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    VStack(spacing: AppConstants.largeSpacing) {
                        Text("Start Claim")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.top, AppConstants.largeSpacing)
                        
                        Text("Choose the fastest way to start your claim")
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.6))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, AppConstants.spacing)
                        
                        VStack(spacing: AppConstants.spacing) {
                            // Import from Wallet
                            AddFlightMethodButton(
                                icon: "wallet.pass",
                                title: "Import from Wallet",
                                subtitle: "Fastest option",
                                isPrimary: false
                            ) {
                                Task {
                                    await viewModel.importFromWallet()
                                    if viewModel.errorMessage == nil {
                                        dismiss()
                                    }
                                }
                            }
                            
                            // Scan ticket
                            AddFlightMethodButton(
                                icon: "camera",
                                title: "Scan ticket",
                                subtitle: "Scan your boarding pass",
                                isPrimary: false
                            ) {
                                showTicketScan = true
                            }
                            
                            // Manual entry
                            AddFlightMethodButton(
                                icon: "keyboard",
                                title: "Enter flight number",
                                subtitle: "Type your flight details",
                                isPrimary: false
                            ) {
                                showManualEntry = true
                            }
                        }
                        .padding(.horizontal, AppConstants.spacing)
                        .padding(.top, AppConstants.largeSpacing)
                        
                        if viewModel.isLoading {
                            ProgressView()
                                .tint(.white)
                                .padding(.top, AppConstants.spacing)
                        }
                        
                        Spacer()
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
            .sheet(isPresented: $showManualEntry) {
                ManualEntryView(viewModel: viewModel)
            }
            .sheet(isPresented: $showTicketScan) {
                TicketScanView(viewModel: viewModel)
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
}

struct AddFlightMethodButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let isPrimary: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            HapticsManager.shared.impact(style: isPrimary ? .medium : .light)
            action()
        }) {
            HStack(spacing: AppConstants.spacing) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    // Icon color logic handled in ButtonStyle based on configuration
                    // We'll pass the view content structure here, but styling moves to ButtonStyle
                    // However, due to complex internal styling depending on state, 
                    // a custom ButtonStyle is the cleanest way to access `configuration.isPressed`
                
                // Since we need to access isPressed for the whole row background AND internal elements
                // It's easier to implement the content IN the ButtonStyle or use a style that wraps everything.
            }
        }
        .buttonStyle(AddFlightButtonStyle(icon: icon, title: title, subtitle: subtitle, isPrimary: isPrimary))
    }
}

struct AddFlightButtonStyle: ButtonStyle {
    let icon: String
    let title: String
    let subtitle: String
    let isPrimary: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        let isPressed = configuration.isPressed
        // Highlight if primary OR pressed
        let showHighlight = isPrimary || isPressed
        
        return HStack(spacing: AppConstants.spacing) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(showHighlight ? .white : PremiumTheme.electricBlue)
                .frame(width: 50, height: 50)
                .background(showHighlight ? Color.white.opacity(0.2) : PremiumTheme.electricBlue.opacity(0.15))
                .cornerRadius(12)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                Text(subtitle)
                    .font(.system(size: 14))
                    .foregroundColor(showHighlight ? .white.opacity(0.8) : .white.opacity(0.5))
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(showHighlight ? .white.opacity(0.7) : .white.opacity(0.4))
        }
        .padding(AppConstants.cardPadding)
        .background(
            showHighlight
            ? AnyShapeStyle(PremiumTheme.primaryGradient)
            : AnyShapeStyle(Color.white.opacity(0.08))
        )
        .cornerRadius(AppConstants.cardCornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: AppConstants.cardCornerRadius)
                .stroke(showHighlight ? Color.clear : Color.white.opacity(0.1), lineWidth: 1)
        )
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
    }
}

