import Foundation
import SwiftUI
import Combine
import FirebaseAuth

enum ClaimStep: Int, CaseIterable {
    case passengerDetails = 0
    case disruptionDetails
    case claimTypeSelection
    case evidenceUpload
    case agreements
    case representationSignature
    case review

    var title: String {
        switch self {
        case .passengerDetails: return "Passenger Details"
        case .disruptionDetails: return "What Happened"
        case .claimTypeSelection: return "Situation"
        case .evidenceUpload: return "Documents"
        case .agreements: return "Agreement"
        case .representationSignature: return "Signature"
        case .review: return "Review & Submit"
        }
    }
}

enum ClaimType {
    case airline
    case aesa
}

@MainActor
final class ClaimViewModel: ObservableObject {
    @Published var currentStep: ClaimStep = .passengerDetails
    @Published var claimRequest: ClaimRequest
    @Published var isSubmitting: Bool = false
    @Published var submissionError: String?
    @Published var isSuccess: Bool = false
    @Published var claimReference: String?
    @Published var claimType: ClaimType?
    @Published var canMoveToNext: Bool = false
    @Published var signatureStrokeImage: UIImage?
    @Published private(set) var eligibility: CompensationEligibility
    @Published var isClaimingForMinor: Bool = false {
        didSet {
            claimRequest.passengerDetails.minor = isClaimingForMinor ? (claimRequest.passengerDetails.minor ?? MinorPassenger()) : nil
            validateCurrentStep()
        }
    }

    let flight: Flight
    /// Generated up front: it's printed in the documents the passenger signs.
    let pendingReference: String

    private let submissionService: SubmissionServiceProtocol
    private let eligibilityService: EU261EligibilityService
    private let pdfService = PDFService.shared
    private var cancellables = Set<AnyCancellable>()

    init(flight: Flight,
         submissionService: SubmissionServiceProtocol = FirestoreSubmissionService(),
         eligibilityService: EU261EligibilityService = EU261EligibilityService()) {
        self.flight = flight
        self.submissionService = submissionService
        self.eligibilityService = eligibilityService
        self.pendingReference = ClaimReference.generate()

        var request = ClaimRequest(flightId: flight.id.uuidString)
        if let profile = UserProfileService.shared.userProfile {
            request.passengerDetails.firstName = profile.firstName
            request.passengerDetails.lastName = profile.lastName
            request.passengerDetails.email = profile.email
            request.passengerDetails.phoneNumber = profile.phoneNumber
            request.passengerDetails.documentType = profile.documentType
            request.passengerDetails.documentNumber = profile.documentNumber
            request.passengerDetails.address = profile.address
        }
        if let report = DisruptionReportStore.load(for: flight.id) {
            request.disruption = report
        }
        self.claimRequest = request
        self.eligibility = eligibilityService.assess(flight: flight, delayEvent: flight.latestDelayEvent, report: request.disruption)
        validateCurrentStep()

        // @Published emits before the value changes; hop to the next run loop to validate the new state.
        $claimRequest
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.validateCurrentStep() }
            .store(in: &cancellables)
        $claimRequest
            .map(\.disruption)
            .removeDuplicates()
            .dropFirst()
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.refreshEligibility() }
            .store(in: &cancellables)
    }

    /// Non-optional binding for the minor form fields.
    var minorBinding: Binding<MinorPassenger> {
        Binding(
            get: { self.claimRequest.passengerDetails.minor ?? MinorPassenger() },
            set: { self.claimRequest.passengerDetails.minor = $0 }
        )
    }

    // MARK: - Disruption questions

    var isCancellation: Bool {
        flight.currentStatus == .cancelled || flight.latestDelayEvent?.type == .cancellation
    }

    /// Flight data didn't give us a measured arrival delay, so we ask.
    var needsArrivalDelayAnswer: Bool {
        !isCancellation && !(flight.latestDelayEvent?.isDurationKnown ?? false)
    }

    private var disruptionQuestionsAnswered: Bool {
        let report = claimRequest.disruption
        if isCancellation {
            return report.notice != nil && report.alternativeOffered != nil
        }
        return !needsArrivalDelayAnswer || report.arrivalDelay != nil
    }

    func refreshEligibility() {
        DisruptionReportStore.save(claimRequest.disruption, for: flight.id)
        eligibility = eligibilityService.assess(flight: flight, delayEvent: flight.latestDelayEvent, report: claimRequest.disruption)
        validateCurrentStep()
    }

    // MARK: - Navigation

    func selectClaimType(_ type: ClaimType) {
        self.claimType = type
        validateCurrentStep()
    }

    func validateCurrentStep() {
        switch currentStep {
        case .passengerDetails:
            canMoveToNext = claimRequest.passengerDetails.isValid
        case .disruptionDetails:
            canMoveToNext = disruptionQuestionsAnswered && eligibility.isEligible && eligibility.needsMoreInformation != true
        case .claimTypeSelection:
            canMoveToNext = claimType != nil
        case .evidenceUpload:
            canMoveToNext = claimRequest.evidence.isComplete(requiresIdentityDocument: claimType == .aesa)
        case .agreements:
            canMoveToNext = claimRequest.consents.allRequiredAccepted
        case .representationSignature:
            canMoveToNext = signatureStrokeImage != nil
        case .review:
            canMoveToNext = !isSubmitting
        }
    }

    func nextStep() {
        validateCurrentStep()
        guard canMoveToNext else { return }
        if let next = ClaimStep(rawValue: currentStep.rawValue + 1) {
            currentStep = next
            if next == .disruptionDetails { refreshEligibility() }
            validateCurrentStep()
        }
    }

    func previousStep() {
        if let prev = ClaimStep(rawValue: currentStep.rawValue - 1) {
            currentStep = prev
            validateCurrentStep()
        }
    }

    func saveSignature(_ image: UIImage) {
        signatureStrokeImage = image
        if let data = image.pngData() {
            claimRequest.representationAuth = RepresentationAuth(signatureImage: data, signedDate: Date(), signedLocation: "In app")
        }
        validateCurrentStep()
    }

    func clearSignature() {
        signatureStrokeImage = nil
        claimRequest.representationAuth = nil
        validateCurrentStep()
    }

    // MARK: - Documents

    var amountText: String {
        let amount = NSDecimalNumber(decimal: eligibility.amount).intValue
        return EU261Rules.format(amount, eligibility.currency)
    }

    var netPayoutText: String {
        let amount = NSDecimalNumber(decimal: eligibility.amount).intValue
        return EU261Rules.format(Config.netPayout(for: amount), eligibility.currency)
    }

    /// The exact agreement the passenger reads, accepts and signs.
    var agreement: ClaimAgreementText {
        let p = claimRequest.passengerDetails
        let minor = p.minor
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        dateFormatter.locale = Locale(identifier: "en_GB")

        return ClaimAgreementText(context: .init(
            companyName: Config.companyLegalName,
            companyRegistration: Config.companyRegistrationNumber,
            companyAddress: Config.companyAddress,
            companyEmail: Config.companyEmail,
            termsURL: Config.termsURL,
            privacyURL: Config.privacyURL,
            governingLaw: Config.governingLaw,
            feePercent: Config.successFeePercent,
            legalFeePercent: Config.legalActionFeePercent,
            signerName: p.signerFullName,
            signerEmail: p.email.trimmed,
            signerAddress: p.address.singleLine,
            signerDocument: "\(p.documentType.rawValue) \(p.documentNumber.trimmed)",
            travellerName: p.travellerFullName,
            minorDateOfBirth: minor.map { dateFormatter.string(from: $0.dateOfBirth) },
            minorRelationship: minor?.relationship.trimmed,
            minorSoleCustody: minor?.custody == .sole,
            otherGuardianConsents: minor?.otherGuardianConsents ?? false,
            flightNumber: flight.displayFlightNumber,
            flightDate: dateFormatter.string(from: flight.scheduledDeparture),
            route: "\(flight.departureAirport.code) → \(flight.arrivalAirport.code)",
            airlineName: flight.airline.name,
            bookingReference: p.bookingReference.trimmed.uppercased(),
            regulation: eligibility.regulation ?? "EU261",
            amountText: amountText,
            claimReference: pendingReference
        ))
    }

    private var disruptionSummary: String {
        let report = claimRequest.disruption
        if isCancellation {
            var text = "The flight was cancelled"
            if let notice = report.notice { text += "; the passenger was informed \(notice.rawValue.lowercased()) departure" }
            if report.alternativeOffered == true {
                text += "; the alternative flight arrived \(report.alternativeArrival.rawValue.lowercased())"
            }
            return text + "."
        }
        if let event = flight.latestDelayEvent, event.isDurationKnown {
            return "The flight arrived \(event.formattedDuration) late at the final destination."
        }
        return "The passenger arrived at the final destination \(report.arrivalDelay?.rawValue.lowercased() ?? "more than 3 hours late")."
    }

    func previewAuthorizationPDF() -> Data {
        pdfService.generateAuthorizationPDF(agreement: agreement, signature: signatureStrokeImage, audit: nil)
    }

    // MARK: - Submit

    func submitClaim() async {
        guard !isSubmitting else { return }
        isSubmitting = true
        submissionError = nil
        defer {
            isSubmitting = false
            validateCurrentStep()
        }

        #if DEBUG
        let isTest = true
        #else
        let isTest = false
        guard Config.isLegalEntityConfigured else {
            submissionError = "Claims are not open yet: the company details for the documents are not configured."
            return
        }
        #endif

        guard let signature = signatureStrokeImage else {
            submissionError = "Please sign the authorisation first."
            return
        }
        guard claimRequest.consents.allRequiredAccepted else {
            submissionError = "Please accept the agreement first."
            return
        }

        let agreement = self.agreement
        let passenger = claimRequest.passengerDetails
        var audit = SignatureAudit(
            signerName: passenger.signerFullName,
            signerEmail: passenger.email.trimmed,
            signerUserId: Auth.auth().currentUser?.uid ?? "",
            signedAt: Date(),
            timeZone: TimeZone.current.identifier,
            device: "\(UIDevice.current.model), \(UIDevice.current.systemName) \(UIDevice.current.systemVersion)",
            appVersion: Config.appVersion,
            documentVersion: ClaimDocumentVersion.current,
            contentSHA256: agreement.sha256
        )
        let authorizationPDF = pdfService.generateAuthorizationPDF(agreement: agreement, signature: signature, audit: audit)
        audit.documentSHA256 = ClaimAgreementText.sha256Hex(authorizationPDF)

        let letterPDF: Data? = claimType == .airline
            ? pdfService.generateAirlineClaimLetter(agreement: agreement, disruptionSummary: disruptionSummary)
            : nil

        let reference = pendingReference
        var files = [ClaimSubmission.File(key: "authorization", fileName: ClaimDocumentType.masterAuthorization.filename(for: reference),
                                          contentType: "application/pdf", data: authorizationPDF)]
        if let letterPDF {
            files.append(.init(key: "airlineLetter", fileName: ClaimDocumentType.airlineComplaint.filename(for: reference),
                               contentType: "application/pdf", data: letterPDF))
        }
        let evidence = claimRequest.evidence
        for (key, image) in [("idDocument", evidence.identityDocumentImage),
                             ("boardingPass", evidence.boardingPassImage),
                             ("bookingConfirmation", evidence.bookingConfirmationImage)] {
            if let jpeg = image.flatMap(Self.normalizedJPEG) {
                files.append(.init(key: key, fileName: "\(key)_\(reference).jpg", contentType: "image/jpeg", data: jpeg))
            }
        }

        let submission = ClaimSubmission(
            claimReference: reference,
            claimType: claimType == .aesa ? "aesa" : "airline",
            isTest: isTest,
            fields: firestoreFields(audit: audit),
            files: files
        )

        do {
            let response = try await submissionService.submitClaim(submission)
            ClaimDocumentService.shared.savePDF(data: authorizationPDF, claimReference: response.claimReference, type: .masterAuthorization)
            if let letterPDF {
                ClaimDocumentService.shared.savePDF(data: letterPDF, claimReference: response.claimReference, type: .airlineComplaint)
            }
            claimReference = response.claimReference
            isSuccess = true
        } catch {
            submissionError = error.localizedDescription
        }
    }

    private func firestoreFields(audit: SignatureAudit) -> [String: Any] {
        let p = claimRequest.passengerDetails
        let report = claimRequest.disruption
        let iso = ISO8601DateFormatter()

        var passenger: [String: Any] = [
            "firstName": p.firstName.trimmed,
            "lastName": p.lastName.trimmed,
            "email": p.email.trimmed,
            "phone": p.phoneNumber.trimmed,
            "documentType": p.documentType.rawValue,
            "documentNumber": p.documentNumber.trimmed,
            "address": [
                "street": p.address.street.trimmed,
                "city": p.address.city.trimmed,
                "postalCode": p.address.postalCode.trimmed,
                "country": p.address.country.trimmed
            ]
        ]
        if let minor = p.minor {
            passenger["minor"] = [
                "firstName": minor.firstName.trimmed,
                "lastName": minor.lastName.trimmed,
                "dateOfBirth": iso.string(from: minor.dateOfBirth),
                "relationship": minor.relationship.trimmed,
                "custody": minor.custody == .sole ? "sole" : "joint",
                "otherGuardianConsents": minor.otherGuardianConsents
            ]
        }

        var disruption: [String: Any] = [
            "type": isCancellation ? "cancellation" : "delay",
            "airlineReason": report.airlineReason.trimmed,
            "summary": disruptionSummary
        ]
        if let event = flight.latestDelayEvent, event.isDurationKnown {
            disruption["measuredArrivalDelayMinutes"] = Int(event.duration / 60)
        }
        if let answer = report.arrivalDelay { disruption["reportedArrivalDelay"] = answer.rawValue }
        if let notice = report.notice { disruption["notice"] = notice.rawValue }
        if let offered = report.alternativeOffered {
            disruption["alternativeOffered"] = offered
            if offered {
                disruption["alternativeDeparture"] = report.alternativeDeparture.rawValue
                disruption["alternativeArrival"] = report.alternativeArrival.rawValue
            }
        }

        var eligibilityFields: [String: Any] = [
            "amount": NSDecimalNumber(decimal: eligibility.amount).intValue,
            "currency": eligibility.currency,
            "regulation": eligibility.regulation ?? "",
            "explanation": eligibility.reason
        ]
        if let distance = eligibility.distanceKm { eligibilityFields["distanceKm"] = Int(distance.rounded()) }
        if let warnings = eligibility.warnings { eligibilityFields["warnings"] = warnings }

        let consents = claimRequest.consents
        return [
            "flight": [
                "number": flight.displayFlightNumber,
                "airlineCode": flight.airline.code.uppercased(),
                "airlineName": flight.airline.name,
                "date": iso.string(from: flight.scheduledDeparture),
                "scheduledArrival": iso.string(from: flight.scheduledArrival),
                "from": flight.departureAirport.code,
                "to": flight.arrivalAirport.code,
                "bookingReference": p.bookingReference.trimmed.uppercased()
            ],
            "passenger": passenger,
            "disruption": disruption,
            "eligibility": eligibilityFields,
            "signature": [
                "signerName": audit.signerName,
                "signerEmail": audit.signerEmail,
                "signedAt": iso.string(from: audit.signedAt),
                "timeZone": audit.timeZone,
                "device": audit.device,
                "documentVersion": audit.documentVersion,
                "contentSHA256": audit.contentSHA256,
                "documentSHA256": audit.documentSHA256,
                "feePercent": Config.successFeePercent,
                "legalFeePercent": Config.legalActionFeePercent,
                "consents": [
                    "termsAndFee": consents.acceptedTermsAndFee,
                    "assignmentAndAuthority": consents.acceptedAssignmentAndAuthority,
                    "privacy": consents.acknowledgedPrivacy,
                    "immediateStart": consents.requestedImmediateStart,
                    "truthfulAndExclusive": consents.confirmedTruthfulAndExclusive,
                    "marketing": consents.marketingOptIn
                ]
            ]
        ]
    }

    /// Photos may be HEIC or huge; store a reasonably sized JPEG.
    private static func normalizedJPEG(_ data: Data) -> Data? {
        guard let image = UIImage(data: data) else { return nil }
        let maxSide: CGFloat = 2000
        let scale = min(1, maxSide / max(image.size.width, image.size.height))
        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let resized = UIGraphicsImageRenderer(size: size).image { _ in image.draw(in: CGRect(origin: .zero, size: size)) }
        return resized.jpegData(compressionQuality: 0.75)
    }
}
