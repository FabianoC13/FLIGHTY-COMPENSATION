import SwiftUI

struct PassengerFormView: View {
    @ObservedObject var viewModel: ClaimViewModel
    
    var body: some View {
        VStack(spacing: 24) {
            
            // PErsonal Information
            VStack(alignment: .leading, spacing: 12) {
                Text("Personal Information")
                    .font(.headline)
                    .foregroundStyle(PremiumTheme.electricBlue)
                    .padding(.leading, 4)
                
                VStack(spacing: 16) {
                    PremiumTextField(placeholder: "First Name", text: $viewModel.claimRequest.passengerDetails.firstName, contentType: .givenName)
                    PremiumTextField(placeholder: "Last Name", text: $viewModel.claimRequest.passengerDetails.lastName, contentType: .familyName)
                    PremiumTextField(placeholder: "Email", text: $viewModel.claimRequest.passengerDetails.email, contentType: .emailAddress, keyboardType: .emailAddress)
                    PremiumTextField(placeholder: "Phone Number", text: $viewModel.claimRequest.passengerDetails.phoneNumber, contentType: .telephoneNumber, keyboardType: .phonePad)
                }
                .padding(20)
                .glassCard(cornerRadius: 16)
            }
            
            // Identification
            VStack(alignment: .leading, spacing: 12) {
                Text("Identification")
                    .font(.headline)
                    .foregroundStyle(PremiumTheme.electricBlue)
                    .padding(.leading, 4)
                
                VStack(spacing: 16) {
                    HStack {
                        Text("Type")
                            .foregroundStyle(.white.opacity(0.7))
                        Spacer()
                        Picker("Document Type", selection: $viewModel.claimRequest.passengerDetails.documentType) {
                            ForEach(DocumentType.allCases) { type in
                                Text(type.rawValue).tag(type)
                            }
                        }
                        .tint(.white)
                    }
                    .padding(.horizontal, 10)
                    
                    PremiumTextField(placeholder: "Document Number", text: $viewModel.claimRequest.passengerDetails.documentNumber)
                }
                .padding(20)
                .glassCard(cornerRadius: 16)
            }
            
            // Address
            VStack(alignment: .leading, spacing: 12) {
                Text("Address")
                    .font(.headline)
                    .foregroundStyle(PremiumTheme.electricBlue)
                    .padding(.leading, 4)
                
                VStack(spacing: 16) {
                    PremiumTextField(placeholder: "Street", text: $viewModel.claimRequest.passengerDetails.address.street, contentType: .streetAddressLine1)
                    PremiumTextField(placeholder: "City", text: $viewModel.claimRequest.passengerDetails.address.city, contentType: .addressCity)
                    HStack(spacing: 16) {
                        PremiumTextField(placeholder: "ZIP", text: $viewModel.claimRequest.passengerDetails.address.postalCode, contentType: .postalCode)
                        PremiumTextField(placeholder: "Country", text: $viewModel.claimRequest.passengerDetails.address.country, contentType: .countryName)
                    }
                }
                .padding(20)
                .glassCard(cornerRadius: 16)
            }
        }
        .onChange(of: viewModel.claimRequest.passengerDetails.firstName) { viewModel.validateCurrentStep() }
        .onChange(of: viewModel.claimRequest.passengerDetails.lastName) { viewModel.validateCurrentStep() }
        .onChange(of: viewModel.claimRequest.passengerDetails.email) { viewModel.validateCurrentStep() }
        .onChange(of: viewModel.claimRequest.passengerDetails.documentNumber) { viewModel.validateCurrentStep() }
        .onChange(of: viewModel.claimRequest.passengerDetails.address.street) { viewModel.validateCurrentStep() }
    }
}

