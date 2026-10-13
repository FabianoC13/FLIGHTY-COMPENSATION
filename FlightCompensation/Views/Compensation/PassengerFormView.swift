import SwiftUI

struct PassengerFormView: View {
    @ObservedObject var viewModel: ClaimViewModel

    var body: some View {
        VStack(spacing: 24) {

            // Booking
            FormSection(title: "Booking") {
                PremiumTextField(placeholder: "Booking reference (e.g. ABC123)", text: $viewModel.claimRequest.passengerDetails.bookingReference)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                Text("The 6-character code on your booking confirmation. Airlines ask for it first.")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
            }

            // Minor
            FormSection(title: "Who travelled?") {
                Toggle(isOn: $viewModel.isClaimingForMinor) {
                    Text("I'm claiming for my child (under 18)")
                        .foregroundStyle(.white)
                }
                .tint(PremiumTheme.electricBlue)

                if viewModel.isClaimingForMinor {
                    MinorPassengerFields(minor: viewModel.minorBinding)
                }
            }

            // Personal Information
            FormSection(title: viewModel.isClaimingForMinor ? "Parent or guardian (signs the documents)" : "Personal Information") {
                PremiumTextField(placeholder: "First Name", text: $viewModel.claimRequest.passengerDetails.firstName, contentType: .givenName)
                PremiumTextField(placeholder: "Last Name", text: $viewModel.claimRequest.passengerDetails.lastName, contentType: .familyName)
                PremiumTextField(placeholder: "Email", text: $viewModel.claimRequest.passengerDetails.email, contentType: .emailAddress, keyboardType: .emailAddress)
                PremiumTextField(placeholder: "Phone Number", text: $viewModel.claimRequest.passengerDetails.phoneNumber, contentType: .telephoneNumber, keyboardType: .phonePad)
            }

            // Identification
            FormSection(title: "Identification") {
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

            // Address
            FormSection(title: "Address") {
                PremiumTextField(placeholder: "Street", text: $viewModel.claimRequest.passengerDetails.address.street, contentType: .streetAddressLine1)
                PremiumTextField(placeholder: "City", text: $viewModel.claimRequest.passengerDetails.address.city, contentType: .addressCity)
                HStack(spacing: 16) {
                    PremiumTextField(placeholder: "ZIP", text: $viewModel.claimRequest.passengerDetails.address.postalCode, contentType: .postalCode)
                    PremiumTextField(placeholder: "Country", text: $viewModel.claimRequest.passengerDetails.address.country, contentType: .countryName)
                }
            }
        }
    }
}

struct MinorPassengerFields: View {
    @Binding var minor: MinorPassenger

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            PremiumTextField(placeholder: "Child's first name", text: $minor.firstName)
            PremiumTextField(placeholder: "Child's last name", text: $minor.lastName)
            DatePicker("Date of birth", selection: $minor.dateOfBirth, in: ...Date(), displayedComponents: .date)
                .foregroundStyle(.white)
                .tint(PremiumTheme.electricBlue)
            PremiumTextField(placeholder: "Your relationship (e.g. Mother, Father, Guardian)", text: $minor.relationship)
            Picker("Custody", selection: $minor.custody) {
                ForEach(MinorPassenger.Custody.allCases) { custody in
                    Text(custody.rawValue).tag(custody)
                }
            }
            .pickerStyle(.segmented)
            if minor.custody == .joint {
                Toggle(isOn: $minor.otherGuardianConsents) {
                    Text("The other parent or guardian agrees to this claim")
                        .font(.subheadline)
                        .foregroundStyle(.white)
                }
                .tint(PremiumTheme.electricBlue)
            }
        }
    }
}

/// Titled glass card used by the claim forms.
struct FormSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundStyle(PremiumTheme.electricBlue)
                .padding(.leading, 4)

            VStack(alignment: .leading, spacing: 16) {
                content
            }
            .padding(20)
            .glassCard(cornerRadius: 16)
        }
    }
}
