import Foundation
import PDFKit
import UIKit

enum PDFError: LocalizedError {
    case documentCreationFailed
    case imageConversionFailed

    var errorDescription: String? {
        switch self {
        case .documentCreationFailed: return "Could not create the PDF document."
        case .imageConversionFailed: return "Could not read the signature image."
        }
    }
}

final class PDFService {
    static let shared = PDFService()

    private init() {}

    private let pageRect = CGRect(x: 0, y: 0, width: 595.2, height: 841.8) // A4
    private let margin: CGFloat = 50

    /// The signed authorisation pack: service agreement, assignment of claim, power of attorney
    /// (+ guardian declaration), signature and audit trail. This is what goes to the airline.
    func generateAuthorizationPDF(agreement: ClaimAgreementText, signature: UIImage?, audit: SignatureAudit?) -> Data {
        let renderer = makeRenderer(title: "Claim authorisation \(agreement.context.claimReference)")
        return renderer.pdfData { context in
            var writer = PageWriter(context: context, pageRect: pageRect, margin: margin)
            writer.setFooter("\(agreement.context.companyName) · \(agreement.context.companyRegistration) · Ref. \(agreement.context.claimReference)")
            writer.newPage()
            writer.title("AUTHORISATION, ASSIGNMENT OF CLAIM AND POWER OF ATTORNEY")
            writer.small("Regulation (EC) No 261/2004 · Reference \(agreement.context.claimReference) · Document version \(ClaimDocumentVersion.current)")
            writer.space(12)

            for section in agreement.sections {
                writer.heading(section.title)
                writer.body(section.body)
                writer.space(8)
            }

            writer.ensureSpace(220)
            writer.heading("Signature")
            writer.body("Signed electronically by \(agreement.context.signerName)" +
                        (audit.map { " on \(Self.timestamp($0.signedAt, timeZone: $0.timeZone))" } ?? " (not yet signed)") + ".")
            writer.signatureBox(signature)
            writer.body(agreement.context.signerName)

            if let audit {
                writer.space(10)
                writer.heading("Electronic signature audit trail")
                writer.small("""
                Simple electronic signature (Regulation (EU) No 910/2014, Art. 25(1)), drawn on screen in the app after explicit acceptance of each section and identity confirmation on the device.
                Signer: \(audit.signerName) <\(audit.signerEmail)> · Account ID: \(audit.signerUserId)
                Signed at: \(Self.timestamp(audit.signedAt, timeZone: audit.timeZone)) (\(audit.timeZone)) · ISO 8601: \(ISO8601DateFormatter().string(from: audit.signedAt))
                Device: \(audit.device) · App: \(audit.appVersion) · Document version: \(audit.documentVersion)
                SHA-256 of the accepted text: \(audit.contentSHA256)
                """)
            }
            writer.finish()
        }
    }

    /// Letter to the airline, sent with the authorisation. Written by the company on the passenger's behalf.
    func generateAirlineClaimLetter(agreement: ClaimAgreementText, disruptionSummary: String) -> Data {
        let c = agreement.context
        let renderer = makeRenderer(title: "Compensation claim \(c.claimReference)")
        return renderer.pdfData { context in
            var writer = PageWriter(context: context, pageRect: pageRect, margin: margin)
            writer.setFooter("\(c.companyName) · \(c.companyRegistration) · Ref. \(c.claimReference)")
            writer.newPage()
            writer.small("\(c.companyName)\n\(c.companyAddress)\n\(c.companyEmail)")
            writer.space(16)
            writer.body("To: \(c.airlineName), Customer Relations / Claims\nDate: \(Date().formatted(date: .long, time: .omitted))")
            writer.space(12)
            writer.heading("Claim for compensation under Regulation (EC) No 261/2004 · Ref. \(c.claimReference)")
            writer.space(4)

            var payment = "Please pay the compensation by bank transfer"
            if let iban = Config.collectionIBAN {
                payment += " to \(c.companyName), IBAN \(iban)" + (Config.collectionBIC.map { ", BIC \($0)" } ?? "")
            } else {
                payment += " to the account we will confirm in reply to your acknowledgement"
            }
            payment += ", quoting reference \(c.claimReference)."

            writer.body("""
            Dear Sir or Madam,

            We act on behalf of \(c.travellerName) under the attached signed authorisation and assignment of claim.

            Passenger: \(c.travellerName)
            Booking reference: \(c.bookingReference)
            Flight: \(c.flightNumber), \(c.flightDate), \(c.route)
            What happened: \(disruptionSummary)

            Under Articles 5, 6 and 7 of Regulation (EC) No 261/2004, as interpreted by the Court of Justice of the EU (Sturgeon, C-402/07 and C-432/07; Nelson, C-581/10), the passenger is entitled to compensation of \(c.amountText). Please note that, under Article 15 of the Regulation and the judgment in case C-11/23, contractual clauses restricting the assignment of these rights have no effect.

            We ask you to pay the compensation within 14 days. \(payment)

            If you consider that extraordinary circumstances within the meaning of Article 5(3) apply, please provide evidence of them and of the reasonable measures taken.

            Please send all correspondence about this claim to \(c.companyEmail).

            Kind regards,

            \(c.companyName)
            on behalf of \(c.travellerName)
            """)
            writer.finish()
        }
    }

    // MARK: - Helpers

    private func makeRenderer(title: String) -> UIGraphicsPDFRenderer {
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = [
            kCGPDFContextCreator as String: "FlightCompensation \(Config.appVersion)",
            kCGPDFContextAuthor as String: Config.companyLegalName,
            kCGPDFContextTitle as String: title
        ]
        return UIGraphicsPDFRenderer(bounds: pageRect, format: format)
    }

    static func timestamp(_ date: Date, timeZone: String) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_GB")
        formatter.timeZone = TimeZone(identifier: timeZone) ?? .current
        formatter.dateFormat = "d MMM yyyy, HH:mm:ss"
        return formatter.string(from: date)
    }
}

/// Flows text down A4 pages, starting a new page when the current one is full.
private struct PageWriter {
    let context: UIGraphicsPDFRendererContext
    let pageRect: CGRect
    let margin: CGFloat
    private(set) var y: CGFloat = 0
    private var footerText: String?

    init(context: UIGraphicsPDFRendererContext, pageRect: CGRect, margin: CGFloat) {
        self.context = context
        self.pageRect = pageRect
        self.margin = margin
    }

    private var contentWidth: CGFloat { pageRect.width - margin * 2 }
    private var bottomLimit: CGFloat { pageRect.height - margin - 20 }

    mutating func newPage() {
        if y > 0 { drawFooter() }
        context.beginPage()
        y = margin
    }

    mutating func ensureSpace(_ height: CGFloat) {
        if y + height > bottomLimit { newPage() }
    }

    mutating func space(_ height: CGFloat) { y += height }

    mutating func title(_ text: String) {
        let style = NSMutableParagraphStyle()
        style.alignment = .center
        draw(text, attributes: [.font: UIFont.boldSystemFont(ofSize: 14), .paragraphStyle: style])
        y += 4
    }

    mutating func heading(_ text: String) {
        draw(text, attributes: [.font: UIFont.boldSystemFont(ofSize: 11)])
        y += 3
    }

    mutating func body(_ text: String) {
        let style = NSMutableParagraphStyle()
        style.alignment = .justified
        style.paragraphSpacing = 4
        for paragraph in text.components(separatedBy: "\n") {
            draw(paragraph.isEmpty ? " " : paragraph, attributes: [.font: UIFont.systemFont(ofSize: 9.5), .paragraphStyle: style])
        }
    }

    mutating func small(_ text: String) {
        for line in text.components(separatedBy: "\n") {
            draw(line, attributes: [.font: UIFont.systemFont(ofSize: 7.5), .foregroundColor: UIColor.darkGray])
        }
    }

    mutating func signatureBox(_ image: UIImage?) {
        ensureSpace(110)
        let rect = CGRect(x: margin, y: y + 4, width: 240, height: 96)
        UIColor.lightGray.setStroke()
        let path = UIBezierPath(rect: rect)
        path.lineWidth = 0.8
        path.stroke()
        image?.draw(in: rect.insetBy(dx: 8, dy: 8))
        y = rect.maxY + 6
    }

    mutating func setFooter(_ text: String) {
        footerText = text
    }

    /// Draws the footer of the last page.
    func finish() {
        drawFooter()
    }

    private func drawFooter() {
        guard let footerText else { return }
        let style = NSMutableParagraphStyle()
        style.alignment = .center
        let rect = CGRect(x: margin, y: pageRect.height - 32, width: contentWidth, height: 14)
        footerText.draw(in: rect, withAttributes: [.font: UIFont.systemFont(ofSize: 7), .foregroundColor: UIColor.gray, .paragraphStyle: style])
    }

    /// Draws one paragraph, splitting it across pages line by line when needed.
    private mutating func draw(_ text: String, attributes: [NSAttributedString.Key: Any]) {
        let attributed = NSAttributedString(string: text, attributes: attributes)
        let bounds = attributed.boundingRect(with: CGSize(width: contentWidth, height: .greatestFiniteMagnitude),
                                             options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil)
        let height = ceil(bounds.height)
        if y + height <= bottomLimit {
            attributed.draw(with: CGRect(x: margin, y: y, width: contentWidth, height: height),
                            options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil)
            y += height
            return
        }
        // Fits on a fresh page: move it there whole.
        if height <= bottomLimit - margin {
            newPage()
            attributed.draw(with: CGRect(x: margin, y: y, width: contentWidth, height: height),
                            options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil)
            y += height
            return
        }
        // Longer than a page: break at word boundaries.
        let words = text.split(separator: " ", omittingEmptySubsequences: false)
        var line = ""
        for word in words {
            let candidate = line.isEmpty ? String(word) : line + " " + word
            let candidateHeight = NSAttributedString(string: candidate, attributes: attributes)
                .boundingRect(with: CGSize(width: contentWidth, height: .greatestFiniteMagnitude),
                              options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil).height
            if y + ceil(candidateHeight) > bottomLimit && !line.isEmpty {
                let chunk = NSAttributedString(string: line, attributes: attributes)
                let chunkHeight = ceil(chunk.boundingRect(with: CGSize(width: contentWidth, height: .greatestFiniteMagnitude),
                                                          options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil).height)
                chunk.draw(with: CGRect(x: margin, y: y, width: contentWidth, height: chunkHeight),
                           options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil)
                newPage()
                line = String(word)
            } else {
                line = candidate
            }
        }
        // The remainder is shorter than the original paragraph, so this recursion always ends.
        if !line.isEmpty && line.count < text.count {
            draw(line, attributes: attributes)
        }
    }
}
