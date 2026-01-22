import SwiftUI
import PhotosUI

struct DocumentUploadView: View {
    @ObservedObject var viewModel: ClaimViewModel
    
    @State private var selectedIdentityItem: PhotosPickerItem?
    
    var body: some View {
        VStack(spacing: 24) {
            Text("We need a copy of your documents to verify your identity and flight details.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding()
            
            
            // Identity Document
            DocumentPickerRow(
                title: "ID / Passport",
                icon: "person.text.rectangle",
                hasData: viewModel.claimRequest.evidence.identityDocumentImage != nil,
                selection: $selectedIdentityItem
            )
            .onChange(of: selectedIdentityItem) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self) {
                        viewModel.claimRequest.evidence.identityDocumentImage = data
                        viewModel.validateCurrentStep()
                    }
                }
            }
            
            Spacer()
        }
        .padding()
    }
}

struct DocumentPickerRow: View {
    let title: String
    let icon: String
    let hasData: Bool
    @Binding var selection: PhotosPickerItem?
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .frame(width: 40)
                .foregroundStyle(PremiumTheme.electricBlue)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.white)
                
                if hasData {
                    Text("Uploaded")
                        .font(.caption)
                        .foregroundStyle(.green)
                } else {
                    Text("Required")
                        .font(.caption)
                        .foregroundStyle(.red.opacity(0.8))
                }
            }
            
            Spacer()
            
            PhotosPicker(selection: $selection, matching: .images) {
                if hasData {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(PremiumTheme.goldStart)
                } else {
                    Text("Upload")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(PremiumTheme.electricBlue)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .stroke(PremiumTheme.electricBlue.opacity(0.5), lineWidth: 1)
                        )
                }
            }
        }
        .padding(20)
        .glassCard(cornerRadius: 16)
    }
}

