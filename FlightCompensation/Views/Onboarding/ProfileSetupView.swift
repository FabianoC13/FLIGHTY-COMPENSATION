import SwiftUI
import PencilKit

struct ProfileSetupView: View {
    @StateObject private var userProfileService = UserProfileService.shared
    @Binding var userProfile: UserProfile
    var onComplete: () -> Void
    
    @State private var canvasView = PKCanvasView()
    @State private var isSignatureEmpty: Bool = true
    
    var body: some View {
        ZStack {
            // Background
            WorldMapBackground()
            
            VStack {
                Text("Complete Your Profile")
                    .font(.title)
                    .fontWeight(.heavy)
                    .foregroundStyle(.white)
                    .padding(.top)
                
                Text("We need a few more details to automate your claims.")
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.7))
                    .padding(.bottom)
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Section: Phone
                        SectionCard(title: "CONTACT") {
                            PremiumTextField(placeholder: "Phone Number", text: $userProfile.phoneNumber, contentType: .telephoneNumber, keyboardType: .phonePad)
                        }
                        
                        // Section: ID
                        SectionCard(title: "IDENTITY DOCUMENT") {
                            VStack(spacing: 16) {
                                HStack {
                                    Text("Type")
                                        .foregroundStyle(.white.opacity(0.7))
                                    Spacer()
                                    Picker("Type", selection: $userProfile.documentType) {
                                        ForEach(DocumentType.allCases) { type in
                                            Text(type.rawValue).tag(type)
                                        }
                                    }
                                    .tint(.white)
                                }
                                .padding(.horizontal, 10)
                                
                                PremiumTextField(placeholder: "Document Number", text: $userProfile.documentNumber)
                            }
                        }
                        
                        // Section: Address
                        SectionCard(title: "ADDRESS") {
                            VStack(spacing: 16) {
                                PremiumTextField(placeholder: "Street Address", text: $userProfile.address.street, contentType: .streetAddressLine1)
                                
                                HStack(spacing: 16) {
                                    PremiumTextField(placeholder: "City", text: $userProfile.address.city, contentType: .addressCity)
                                    PremiumTextField(placeholder: "ZIP", text: $userProfile.address.postalCode, contentType: .postalCode)
                                }
                                
                                PremiumTextField(placeholder: "Country", text: $userProfile.address.country, contentType: .countryName)
                            }
                        }
                        
                        // Section: Signature
                        SectionCard(title: "DIGITAL SIGNATURE") {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Sign below to authorize claims.")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.6))
                                
                                SignatureCanvas(canvasView: $canvasView, onDraw: {
                                    isSignatureEmpty = canvasView.drawing.bounds.isEmpty
                                })
                                .frame(height: 150)
                                .background(Color.white)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(PremiumTheme.electricBlue.opacity(0.5), lineWidth: 2)
                                )
                                
                                HStack {
                                    Spacer()
                                    Button("Clear Signature") {
                                        canvasView.drawing = PKDrawing()
                                        isSignatureEmpty = true
                                    }
                                    .font(.subheadline)
                                    .foregroundStyle(isSignatureEmpty ? Color.gray : PremiumTheme.goldStart)
                                }
                            }
                        }
                    }
                    .padding()
                }
                .scrollIndicators(.hidden)
                
                // Complete Button
                VStack {
                    GradientButton(
                        title: "COMPLETE SETUP",
                        icon: "checkmark",
                        gradient: PremiumTheme.goldGradient,
                        action: {
                            saveAndComplete()
                        },
                        isDisabled: !isFormValid
                    )
                }
                .padding()
            }
        }
        .navigationBarHidden(true)
    }
    
    // Validation
    var isFormValid: Bool {
        !userProfile.phoneNumber.isEmpty &&
        !userProfile.documentNumber.isEmpty &&
        !userProfile.address.street.isEmpty &&
        !userProfile.address.city.isEmpty &&
        !userProfile.address.country.isEmpty &&
        !isSignatureEmpty
    }
    
    private func saveAndComplete() {
        // Save signature
        let image = canvasView.drawing.image(from: canvasView.bounds, scale: 1.0)
        if let data = image.pngData() {
            userProfile.signatureData = data
        }
        
        // Save to usage
        userProfileService.saveProfile(userProfile)
        onComplete()
    }
}

// Helper for consistency
struct SectionCard<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(PremiumTheme.electricBlue)
                .padding(.leading, 4)
            
            content
                .padding(20)
                .glassCard(cornerRadius: 16)
        }
    }
}
