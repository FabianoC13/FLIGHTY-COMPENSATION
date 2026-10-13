import SwiftUI
import PhotosUI

struct DocumentUploadView: View {
    @ObservedObject var viewModel: ClaimViewModel
    
    @State private var selectedBoardingPass: PhotosPickerItem?
    @State private var selectedBooking: PhotosPickerItem?
    @State private var selectedIdentityItem: PhotosPickerItem?

    private var idRequired: Bool { viewModel.claimType == .aesa }
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Add your boarding pass or booking confirmation so we can prove you were on the flight.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding()

            DocumentPickerRow(
                title: "Boarding pass",
                icon: "airplane.circle",
                hasData: viewModel.claimRequest.evidence.boardingPassImage != nil,
                requirement: viewModel.claimRequest.evidence.hasProofOfTravel ? "Optional" : "This or booking confirmation",
                selection: $selectedBoardingPass
            )
            .onChange(of: selectedBoardingPass) { _, item in
                load(item) { viewModel.claimRequest.evidence.boardingPassImage = $0 }
            }

            DocumentPickerRow(
                title: "Booking confirmation",
                icon: "doc.text.image",
                hasData: viewModel.claimRequest.evidence.bookingConfirmationImage != nil,
                requirement: viewModel.claimRequest.evidence.hasProofOfTravel ? "Optional" : "This or boarding pass",
                selection: $selectedBooking
            )
            .onChange(of: selectedBooking) { _, item in
                load(item) { viewModel.claimRequest.evidence.bookingConfirmationImage = $0 }
            }
            
            DocumentPickerRow(
                title: "ID / Passport",
                icon: "person.text.rectangle",
                hasData: viewModel.claimRequest.evidence.identityDocumentImage != nil,
                requirement: idRequired ? "Required by AESA" : "Recommended",
                selection: $selectedIdentityItem
            )
            .onChange(of: selectedIdentityItem) { _, item in
                load(item) { viewModel.claimRequest.evidence.identityDocumentImage = $0 }
            }

            Text(idRequired
                 ? "AESA requires a copy of your ID with every complaint."
                 : "Some airlines ask for a copy of your ID to verify your signature. We only share it when they do.")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.6))
                .multilineTextAlignment(.center)
            
            Spacer()
        }
        .padding()
    }

    private func load(_ item: PhotosPickerItem?, into assign: @escaping (Data) -> Void) {
        Task {
            if let data = try? await item?.loadTransferable(type: Data.self) {
                assign(data)
                viewModel.validateCurrentStep()
            }
        }
    }
}

struct DocumentPickerRow: View {
    let title: String
    let icon: String
    let hasData: Bool
    var requirement: String = "Required"
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
                    Text(requirement)
                        .font(.caption)
                        .foregroundStyle(requirement.hasPrefix("Optional") || requirement == "Recommended" ? Color.white.opacity(0.6) : Color.red.opacity(0.8))
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

