import Foundation
import CryptoKit

/// Wording of the documents a passenger signs in the app.
///
/// Structure follows market practice (AirHelp, Flightright, Skycop, AirAdvisor; see
/// `docs/research/competitor-claim-flows.md`): a service & fee agreement, a fiduciary assignment
/// of the claim with a fallback power of attorney, a guardian declaration for minors and a
/// privacy notice. HAVE A LAWYER REVIEW THIS TEXT before launch; bump
/// `ClaimDocumentVersion.current` whenever it changes.
struct ClaimAgreementText {

    struct Context {
        var companyName: String
        var companyRegistration: String
        var companyAddress: String
        var companyEmail: String
        var termsURL: String
        var privacyURL: String
        var governingLaw: String
        var feePercent: Int
        var legalFeePercent: Int

        var signerName: String
        var signerEmail: String
        var signerAddress: String
        var signerDocument: String
        var travellerName: String
        /// Present when a parent/guardian signs for a child.
        var minorDateOfBirth: String?
        var minorRelationship: String?
        var minorSoleCustody: Bool
        var otherGuardianConsents: Bool

        var flightNumber: String
        var flightDate: String
        var route: String
        var airlineName: String
        var bookingReference: String
        var regulation: String
        var amountText: String
        var claimReference: String
    }

    struct Section: Equatable {
        let title: String
        let body: String
    }

    let context: Context

    var sections: [Section] {
        let c = context
        var result: [Section] = []

        result.append(Section(title: "1. Parties and claim", body: """
        Client: \(c.signerName), \(c.signerAddress), ID \(c.signerDocument), \(c.signerEmail)\(c.minorDateOfBirth != nil ? ", acting as \(c.minorRelationship ?? "parent/guardian") of \(c.travellerName) (born \(c.minorDateOfBirth!))" : "").
        Company: \(c.companyName), \(c.companyRegistration), \(c.companyAddress), \(c.companyEmail).
        Claim: compensation under \(c.regulation) (Regulation (EC) No 261/2004, Art. 7), currently estimated at \(c.amountText), plus interest and recoverable costs, for passenger \(c.travellerName) on flight \(c.flightNumber) of \(c.airlineName) on \(c.flightDate), route \(c.route), booking reference \(c.bookingReference). Claim reference \(c.claimReference).
        """))

        result.append(Section(title: "2. Service agreement and fee", body: """
        2.1 The Company will pursue the Claim out of court against the airline and, where useful, before the competent national enforcement body or alternative dispute resolution body. With the Client's prior notice it may instruct a partner lawyer to take legal action, at no cost risk to the Client.
        2.2 No win, no fee. If compensation is recovered the Company keeps a success fee of \(c.feePercent)% of the amount recovered, VAT included. If legal action is needed an additional \(c.legalFeePercent)% applies, VAT included. Court and lawyer costs are borne by the Company. If nothing is recovered the Client pays nothing.
        2.3 The Company pays the remaining amount to the Client's bank account within 14 days of receiving the funds, with a statement showing the amount recovered, the fee and the net payout.
        2.4 If the airline pays the Client directly, or offers a voucher or settlement, the Client informs the Company within 7 days and pays the agreed fee on the amount received.
        2.5 The Client provides true and complete information, forwards any correspondence from the airline, does not instruct any other company or lawyer for this Claim and does not settle directly with the airline while this agreement is in force.
        2.6 The Company may accept a settlement of at least 80% of the amount claimed. It never accepts vouchers instead of money without the Client's consent.
        2.7 Right of withdrawal: the Client may withdraw from this agreement within 14 days without giving a reason by writing to \(c.companyEmail). The Client asks the Company to start work immediately. If the airline has already paid when the Client withdraws, the fee in 2.2 is due for the service provided.
        2.8 Governing law: \(c.governingLaw), without prejudice to the mandatory consumer protection rules of the Client's country of residence. Full terms: \(c.termsURL).
        """))

        result.append(Section(title: "3. Assignment of claim", body: """
        3.1 The Client assigns the Claim described in section 1, including interest and costs, to the Company, which accepts it. The assignment is fiduciary: the Company enforces the Claim in its own name and on the Client's account, and pays the Client the amount recovered less the fee in section 2.
        3.2 The Client confirms the Claim has not been assigned, pledged, settled or paid, and that no other company or lawyer has been instructed to pursue it.
        3.3 The Company may notify the airline of this assignment and present this document as the deed of assignment. Under Article 15 of Regulation 261/2004 and the judgment of the Court of Justice of the EU in case C-11/23, contractual clauses of the airline prohibiting the assignment of these rights are not effective.
        3.4 If the airline, an authority or a court requires it, the Client will sign this assignment again on paper or with a qualified electronic signature.
        3.5 The Company re-assigns the Claim to the Client if this agreement ends, or if legal action in the Client's own name becomes necessary.
        3.6 If this assignment is not accepted or is held invalid, it is to be treated as the power of attorney in section 4.
        """))

        result.append(Section(title: "4. Power of attorney", body: """
        4.1 The Client authorises the Company to act on the Client's behalf in relation to the Claim before the airline, its agents, national enforcement bodies (including AESA in Spain) and alternative dispute resolution bodies: to file the claim and complaints, request booking and flight information, receive notifications and correspondence, and negotiate.
        4.2 The Company may appoint a lawyer and grant sub-authority to them. If a court requires a power of attorney in a specific form, the Client will sign it.
        4.3 The Client authorises the Company to receive payment of the compensation into the Company's client account and deduct the agreed fee.
        4.4 This authority lasts until the Claim is closed and may be revoked as set out in the terms. The Client agrees that a copy of their ID document may be shared with the airline or an authority only to verify this signature, when they request it.
        """))

        if c.minorDateOfBirth != nil {
            let custody = c.minorSoleCustody
                ? "has sole parental responsibility for the child"
                : "shares parental responsibility for the child and declares that the other parent or guardian agrees to this claim and to the signature of these documents on the child's behalf"
            result.append(Section(title: "5. Declaration of parent or guardian", body: """
            The signer, \(c.signerName), declares that they are the \(c.minorRelationship ?? "parent/guardian") of \(c.travellerName), born \(c.minorDateOfBirth!), that they \(custody), and that they sign sections 2 to 4 on the child's behalf. The compensation is paid to the signer's account for the benefit of the child. The signer will provide a birth certificate or proof of custody on request.
            """))
        }

        result.append(Section(title: "\(c.minorDateOfBirth != nil ? 6 : 5). Personal data", body: """
        The Company processes the Client's data to perform this agreement (GDPR Art. 6(1)(b)) and shares it only as needed to pursue the Claim: with the airline, enforcement and dispute resolution bodies, partner lawyers, courts, and payment and electronic signature providers. ID documents are used only to verify the signature and are deleted when the Claim is closed. Data is kept for as long as legal obligations require. Rights of access, rectification, erasure and objection can be exercised at \(c.companyEmail). Privacy notice: \(c.privacyURL).
        """))

        return result
    }

    /// Exactly what the passenger reads; hashed into the audit trail.
    var plainText: String {
        sections.map { "\($0.title)\n\($0.body)" }.joined(separator: "\n\n")
    }

    var sha256: String {
        Self.sha256Hex(Data(plainText.utf8))
    }

    static func sha256Hex(_ data: Data) -> String {
        SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }
}
