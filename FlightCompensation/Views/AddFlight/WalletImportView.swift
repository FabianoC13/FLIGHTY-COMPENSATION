import SwiftUI

struct WalletImportView: View {
    @ObservedObject var viewModel: AddFlightViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: AppConstants.largeSpacing) {
                Image(systemName: "wallet.pass")
                    .font(.system(size: 64))
                    .foregroundColor(.accentColor)
                    .padding(.top, AppConstants.largeSpacing * 2)
                
                Text("Importing from Wallet")
                    .font(.system(size: 24, weight: .semibold))
                
                if viewModel.isLoading {
                    ProgressView()
                } else {
                    Text("Tap below to import your boarding pass from Apple Wallet")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, AppConstants.spacing)
                    
                    Button(action: {
                        Task {
                            await viewModel.importFromWallet()
                            if viewModel.errorMessage == nil {
                                dismiss()
                            }
                        }
                    }) {
                        Text("Import from Wallet")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.accentColor)
                            .cornerRadius(AppConstants.cardCornerRadius)
                    }
                    .padding(.horizontal, AppConstants.spacing)
                }
                
                Spacer()
            }
            .navigationTitle("Wallet Import")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}


