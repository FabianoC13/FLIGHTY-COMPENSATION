import SwiftUI

/// View for collecting customer bank/payout details after claim approval
struct PayoutDetailsView: View {
    let claimId: UUID
    let compensationAmount: Decimal
    let onSave: (PayoutRecipient) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: PayoutDetailsViewModel
    
    init(claimId: UUID, customerId: UUID, compensationAmount: Decimal, onSave: @escaping (PayoutRecipient) -> Void) {
        self.claimId = claimId
        self.compensationAmount = compensationAmount
        self.onSave = onSave
        _viewModel = StateObject(wrappedValue: PayoutDetailsViewModel(claimId: claimId, customerId: customerId))
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        headerSection
                        
                        // Payout Method Toggle
                        payoutMethodSection
                        
                        // Country Selection
                        countrySection
                        
                        // Bank Details (if bank method)
                        if viewModel.recipient.payoutMethod == .bank {
                            bankDetailsSection
                        }
                        
                        // Card Details (if card method)
                        if viewModel.recipient.payoutMethod == .card {
                            cardDetailsSection
                        }
                        
                        // Personal Details
                        personalDetailsSection
                        
                        // Address
                        addressSection
                        
                        // Validation Errors
                        if !viewModel.validationErrors.isEmpty {
                            validationErrorsSection
                        }
                        
                        // Save Button
                        saveButton
                    }
                    .padding()
                }
            }
            .navigationTitle("Payment Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "An error occurred")
            }
        }
    }
    
    // MARK: - Sections
    
    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "banknote")
                .font(.system(size: 48))
                .foregroundStyle(
                    LinearGradient(colors: [.yellow, .orange], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
            
            Text("Receive Your Compensation")
                .font(.title2.bold())
                .foregroundColor(.white)
            
            Text("€\(NSDecimalNumber(decimal: compensationAmount).stringValue)")
                .font(.system(size: 36, weight: .bold))
                .foregroundStyle(
                    LinearGradient(colors: [.green, .mint], startPoint: .leading, endPoint: .trailing)
                )
            
            Text("Enter your bank details to receive payment within 48 hours of AESA settlement")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(.vertical)
    }
    
    private var payoutMethodSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Payment Method")
            
            HStack(spacing: 12) {
                ForEach(PayoutMethod.allCases) { method in
                    PayoutMethodButton(
                        method: method,
                        isSelected: viewModel.recipient.payoutMethod == method
                    ) {
                        withAnimation {
                            viewModel.recipient.payoutMethod = method
                        }
                    }
                }
            }
        }
    }
    
    private var countrySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Country")
            
            Menu {
                ForEach(PayoutCountry.supported) { country in
                    Button {
                        viewModel.selectCountry(country)
                    } label: {
                        HStack {
                            Text(countryFlag(country.code))
                            Text(country.name)
                            if viewModel.recipient.country == country.code {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack {
                    if let country = PayoutCountry.find(byCode: viewModel.recipient.country) {
                        Text(countryFlag(country.code))
                        Text(country.name)
                    } else {
                        Text("Select Country")
                            .foregroundColor(.gray)
                    }
                    Spacer()
                    Image(systemName: "chevron.down")
                        .foregroundColor(.gray)
                }
                .padding()
                .background(Color.white.opacity(0.1))
                .cornerRadius(12)
            }
            .foregroundColor(.white)
        }
    }
    
    private var bankDetailsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("Bank Details")
            
            // IBAN Field
            VStack(alignment: .leading, spacing: 4) {
                Text("IBAN")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                HStack {
                    TextField("ES91 2100 0418 4502 0005 1332", text: $viewModel.ibanInput)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .onChange(of: viewModel.ibanInput) { _, newValue in
                            viewModel.validateIBAN(newValue)
                        }
                    
                    if viewModel.isValidatingIBAN {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else if viewModel.ibanValidationResult?.isValid == true {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    } else if viewModel.ibanValidationResult != nil {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.red)
                    }
                }
                .padding()
                .background(Color.white.opacity(0.1))
                .cornerRadius(12)
                .foregroundColor(.white)
                
                if let result = viewModel.ibanValidationResult, !result.isValid, let error = result.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                }
                
                if let bic = viewModel.inferredBIC {
                    Text("BIC: \(bic)")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
            
            // BIC Field (if required)
            if viewModel.requiresBIC {
                VStack(alignment: .leading, spacing: 4) {
                    Text("BIC / SWIFT Code")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    TextField("CAIXESBBXXX", text: Binding(
                        get: { viewModel.recipient.bic ?? "" },
                        set: { viewModel.recipient.bic = $0.isEmpty ? nil : $0 }
                    ))
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .padding()
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(12)
                    .foregroundColor(.white)
                }
            }
            
            // Account Holder Name
            VStack(alignment: .leading, spacing: 4) {
                Text("Account Holder Name")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                TextField("As shown on bank account", text: Binding(
                    get: { viewModel.recipient.accountHolderName ?? "" },
                    set: { viewModel.recipient.accountHolderName = $0.isEmpty ? nil : $0 }
                ))
                .padding()
                .background(Color.white.opacity(0.1))
                .cornerRadius(12)
                .foregroundColor(.white)
            }
            
            // Currency Preference
            VStack(alignment: .leading, spacing: 4) {
                Text("Receive Payment In")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Menu {
                    ForEach(viewModel.availableCurrencies, id: \.self) { currency in
                        Button {
                            viewModel.recipient.currencyPreferred = currency
                        } label: {
                            HStack {
                                Text(currency)
                                if viewModel.recipient.currencyPreferred == currency {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack {
                        Text(viewModel.recipient.currencyPreferred)
                        Spacer()
                        Image(systemName: "chevron.down")
                            .foregroundColor(.gray)
                    }
                    .padding()
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(12)
                }
                .foregroundColor(.white)
            }
        }
    }
    
    private var cardDetailsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("Card Details")
            
            // Card Number
            VStack(alignment: .leading, spacing: 4) {
                Text("Card Number")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                HStack {
                    TextField("4242 4242 4242 4242", text: $viewModel.cardNumber)
                        .keyboardType(.numberPad)
                        .onChange(of: viewModel.cardNumber) { _, newValue in
                            viewModel.cardNumber = viewModel.formatCardNumber(newValue)
                        }
                    
                    if let brand = viewModel.cardBrand {
                        Image(systemName: cardBrandIcon(brand))
                            .foregroundColor(.white)
                    }
                }
                .padding()
                .background(Color.white.opacity(0.1))
                .cornerRadius(12)
                .foregroundColor(.white)
            }
            
            HStack(spacing: 12) {
                // Expiry Date
                VStack(alignment: .leading, spacing: 4) {
                    Text("Expiry Date")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    TextField("MM/YY", text: $viewModel.cardExpiry)
                        .keyboardType(.numberPad)
                        .onChange(of: viewModel.cardExpiry) { _, newValue in
                            viewModel.cardExpiry = viewModel.formatExpiry(newValue)
                        }
                        .padding()
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(12)
                        .foregroundColor(.white)
                }
                
                // CVC
                VStack(alignment: .leading, spacing: 4) {
                    Text("CVC")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    SecureField("123", text: $viewModel.cardCVC)
                        .keyboardType(.numberPad)
                        .padding()
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(12)
                        .foregroundColor(.white)
                }
            }
            
            // Cardholder Name
            VStack(alignment: .leading, spacing: 4) {
                Text("Cardholder Name")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                TextField("Name on card", text: Binding(
                    get: { viewModel.recipient.accountHolderName ?? "" },
                    set: { viewModel.recipient.accountHolderName = $0.isEmpty ? nil : $0 }
                ))
                .textInputAutocapitalization(.words)
                .padding()
                .background(Color.white.opacity(0.1))
                .cornerRadius(12)
                .foregroundColor(.white)
            }
            
            // Info about card payouts
            HStack(spacing: 8) {
                Image(systemName: "info.circle")
                    .foregroundColor(.blue)
                Text("Card payouts typically arrive within 1-3 business days")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(8)
        }
    }
    
    private func cardBrandIcon(_ brand: String) -> String {
        switch brand.lowercased() {
        case "visa": return "creditcard.fill"
        case "mastercard": return "creditcard.fill"
        case "amex": return "creditcard.fill"
        default: return "creditcard"
        }
    }
    
    private var personalDetailsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("Personal Details")
            
            HStack(spacing: 12) {
                // First Name
                VStack(alignment: .leading, spacing: 4) {
                    Text("First Name")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    TextField("John", text: $viewModel.recipient.firstName)
                        .padding()
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(12)
                        .foregroundColor(.white)
                }
                
                // Last Name
                VStack(alignment: .leading, spacing: 4) {
                    Text("Last Name")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    TextField("Doe", text: $viewModel.recipient.lastName)
                        .padding()
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(12)
                        .foregroundColor(.white)
                }
            }
            
            // Email
            VStack(alignment: .leading, spacing: 4) {
                Text("Email")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                TextField("john@example.com", text: $viewModel.recipient.email)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .padding()
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(12)
                    .foregroundColor(.white)
            }
            
            // Phone (Optional)
            VStack(alignment: .leading, spacing: 4) {
                Text("Phone (Optional)")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                TextField("+34 600 123 456", text: Binding(
                    get: { viewModel.recipient.phone ?? "" },
                    set: { viewModel.recipient.phone = $0.isEmpty ? nil : $0 }
                ))
                .keyboardType(.phonePad)
                .padding()
                .background(Color.white.opacity(0.1))
                .cornerRadius(12)
                .foregroundColor(.white)
            }
            
            // Document Type & Number
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Document Type")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Menu {
                        ForEach(PayoutDocumentType.allCases) { docType in
                            Button {
                                viewModel.recipient.documentType = docType
                            } label: {
                                HStack {
                                    Text(docType.rawValue)
                                    if viewModel.recipient.documentType == docType {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack {
                            Text(viewModel.recipient.documentType.rawValue)
                            Spacer()
                            Image(systemName: "chevron.down")
                                .foregroundColor(.gray)
                        }
                        .padding()
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(12)
                    }
                    .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Document Number")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    TextField("12345678A", text: $viewModel.recipient.documentNumber)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .padding()
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(12)
                        .foregroundColor(.white)
                }
            }
            
            // Date of Birth (if required)
            if viewModel.requiresDOB {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Date of Birth")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    DatePicker(
                        "Date of Birth",
                        selection: Binding(
                            get: { viewModel.recipient.dateOfBirth ?? Date() },
                            set: { viewModel.recipient.dateOfBirth = $0 }
                        ),
                        in: ...Date(),
                        displayedComponents: .date
                    )
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .padding()
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(12)
                    .colorScheme(.dark)
                }
            }
        }
    }
    
    private var addressSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("Address")
            
            // Street
            VStack(alignment: .leading, spacing: 4) {
                Text("Street Address")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                TextField("123 Main Street", text: $viewModel.recipient.addressStreet)
                    .padding()
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(12)
                    .foregroundColor(.white)
            }
            
            HStack(spacing: 12) {
                // City
                VStack(alignment: .leading, spacing: 4) {
                    Text("City")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    TextField("Madrid", text: $viewModel.recipient.addressCity)
                        .padding()
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(12)
                        .foregroundColor(.white)
                }
                
                // Postal Code
                VStack(alignment: .leading, spacing: 4) {
                    Text("Postal Code")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    TextField("28001", text: $viewModel.recipient.addressPostal)
                        .keyboardType(.default)
                        .padding()
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(12)
                        .foregroundColor(.white)
                }
            }
        }
    }
    
    private var validationErrorsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(viewModel.validationErrors, id: \.self) { error in
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundColor(.red)
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
        }
        .padding()
        .background(Color.red.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var saveButton: some View {
        Button {
            Task {
                if let savedRecipient = await viewModel.saveRecipient() {
                    onSave(savedRecipient)
                    dismiss()
                }
            }
        } label: {
            HStack {
                if viewModel.isSaving {
                    ProgressView()
                        .tint(.black)
                } else {
                    Image(systemName: "checkmark.shield.fill")
                    Text("Save Payment Details")
                }
            }
            .font(.headline)
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                LinearGradient(colors: [.yellow, .orange], startPoint: .leading, endPoint: .trailing)
            )
            .cornerRadius(16)
        }
        .disabled(viewModel.isSaving || !viewModel.isFormValid)
        .opacity(viewModel.isFormValid ? 1.0 : 0.5)
        .padding(.top)
    }
    
    // MARK: - Helpers
    
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.headline)
            .foregroundColor(.white)
    }
    
    private func countryFlag(_ code: String) -> String {
        let base: UInt32 = 127397
        var flag = ""
        for scalar in code.uppercased().unicodeScalars {
            if let unicode = UnicodeScalar(base + scalar.value) {
                flag.append(String(unicode))
            }
        }
        return flag
    }
}

// MARK: - Payout Method Button

struct PayoutMethodButton: View {
    let method: PayoutMethod
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: method.icon)
                    .font(.title2)
                Text(method.rawValue)
                    .font(.caption)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                isSelected
                    ? LinearGradient(colors: [.blue.opacity(0.3), .purple.opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    : LinearGradient(colors: [Color.white.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing)
            )
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .foregroundColor(.white)
    }
}

// MARK: - Preview

#Preview {
    PayoutDetailsView(
        claimId: UUID(),
        customerId: UUID(),
        compensationAmount: 400
    ) { _ in }
}
