import SwiftUI
import PDFKit

/// Shows the documents the passenger is about to sign, section by section, and collects
/// explicit acceptance of each one before the signature step.
struct ClaimAgreementsView: View {
    @ObservedObject var viewModel: ClaimViewModel
    @State private var previewData: PreviewData?

    struct PreviewData: Identifiable {
        let id = UUID()
        let data: Data
    }

    private var consents: Binding<ClaimConsents> { $viewModel.claimRequest.consents }

    var body: some View {
        VStack(spacing: 24) {
            FormSection(title: "No win, no fee") {
                Text("If we recover \(viewModel.amountText), you receive \(viewModel.netPayoutText). Our fee is \(Config.successFeePercent)% (VAT included), plus \(Config.legalActionFeePercent)% only if we have to go to court. If we don't win, you pay nothing.")
                    .foregroundStyle(.white)
            }

            FormSection(title: "What you're signing") {
                ForEach(viewModel.agreement.sections, id: \.title) { section in
                    DisclosureGroup {
                        Text(section.body)
                            .font(.footnote)
                            .foregroundStyle(.white.opacity(0.85))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, 6)
                    } label: {
                        Text(section.title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                    }
                    .tint(PremiumTheme.electricBlue)
                }

                Button {
                    previewData = PreviewData(data: viewModel.previewAuthorizationPDF())
                } label: {
                    Label("Read the full document (PDF)", systemImage: "doc.richtext")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(PremiumTheme.electricBlue)
                }
            }

            FormSection(title: "Your agreement") {
                ConsentRow(isOn: consents.acceptedTermsAndFee,
                           text: "I accept the service agreement and the \(Config.successFeePercent)% success fee (section 2) and the terms at \(Config.termsURL).")
                ConsentRow(isOn: consents.acceptedAssignmentAndAuthority,
                           text: "I assign this claim to \(Config.companyLegalName) and authorise it to act for me (sections 3 and 4).")
                ConsentRow(isOn: consents.requestedImmediateStart,
                           text: "Start work now. I keep my right to withdraw within 14 days.")
                ConsentRow(isOn: consents.confirmedTruthfulAndExclusive,
                           text: "The information I gave is true, and no other company or lawyer is handling this claim.")
                ConsentRow(isOn: consents.acknowledgedPrivacy,
                           text: "I have read the privacy notice (\(Config.privacyURL)).")
                Divider().background(Color.white.opacity(0.1))
                ConsentRow(isOn: consents.marketingOptIn,
                           text: "Optional: send me tips and offers by email.")
            }
        }
        .sheet(item: $previewData) { preview in
            NavigationStack {
                PDFDataView(data: preview.data)
                    .ignoresSafeArea(edges: .bottom)
                    .navigationTitle("Authorisation")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") { previewData = nil }
                        }
                    }
            }
        }
    }
}

struct ConsentRow: View {
    @Binding var isOn: Bool
    let text: String

    var body: some View {
        Button {
            isOn.toggle()
            HapticsManager.shared.impact(style: .light)
        } label: {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: isOn ? "checkmark.square.fill" : "square")
                    .font(.title3)
                    .foregroundStyle(isOn ? PremiumTheme.goldStart : Color.white.opacity(0.5))
                Text(text)
                    .font(.subheadline)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.leading)
                Spacer(minLength: 0)
            }
        }
        .buttonStyle(.plain)
    }
}

struct PDFDataView: UIViewRepresentable {
    let data: Data

    func makeUIView(context: Context) -> PDFView {
        let view = PDFView()
        view.autoScales = true
        view.document = PDFDocument(data: data)
        return view
    }

    func updateUIView(_ view: PDFView, context: Context) {}
}
