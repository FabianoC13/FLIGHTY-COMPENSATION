import Foundation
import PDFKit
import SwiftUI

enum PDFError: Error {
    case documentCreationFailed
    case imageConversionFailed
}

final class PDFService {
    static let shared = PDFService()
    
    private init() {}
    
    /// Generates the Consolidated "Master Authorization" PDF
    /// Includes: Representation (AESA/Court) + Fund Assignment (Collection)
    /// Generates the Consolidated "Master Authorization" PDF
    /// Includes: Representation (AESA/Court) + Fund Assignment (Collection)
    func generateMasterAuthorizationPDF(userProfile: UserProfile, flight: Flight, signature: UIImage) throws -> Data {
        let pdfMetaData = [
            kCGPDFContextCreator: "FlightCompensation App",
            kCGPDFContextAuthor: "Flighty Compensation AI"
        ]
        
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        let pageWidth = 595.2
        let pageHeight = 841.8
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        let data = renderer.pdfData { (context) in
            context.beginPage()
            let margin: CGFloat = 50.0
            let contentWidth = pageWidth - (margin * 2)
            var currentY: CGFloat = margin
            
            // --- HEADER ---
            let title = "AUTORIZACIÓN INTEGRAL / MASTER AUTHORIZATION"
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 16),
                .paragraphStyle: centeredParagraphStyle()
            ]
            title.draw(in: CGRect(x: margin, y: currentY, width: contentWidth, height: 20), withAttributes: titleAttributes)
            currentY += 40
            
            drawLine(context: context.cgContext, from: CGPoint(x: margin, y: currentY), to: CGPoint(x: pageWidth - margin, y: currentY))
            currentY += 20
            
            // --- PERSONS ---
            drawSectionHeader(text: "1. OTORGANTE (PASAJERO) / GRANTOR (PASSENGER)", y: currentY, width: contentWidth)
            currentY += 20
            
            let passengerInfo = """
            Nombre / Name: \(userProfile.firstName) \(userProfile.lastName)
            Documento / ID: \(userProfile.documentNumber)
            Email: \(userProfile.email)
            Teléfono / Phone: \(userProfile.phoneNumber)
            """
            _ = drawBodyText(text: passengerInfo, y: currentY, width: contentWidth)
            currentY += 70
            
            drawSectionHeader(text: "2. ENTIDAD AUTORIZADA / AUTHORIZED ENTITY", y: currentY, width: contentWidth)
            currentY += 20
            
            let appCompanyInfo = """
            Nombre / Name: Flighty Compensation System
            Entidad / Entity: Flighty Legal Services S.L.
            Email: legal@flightycompensation.com
            """
            _ = drawBodyText(text: appCompanyInfo, y: currentY, width: contentWidth)
            currentY += 60
            
            drawSectionHeader(text: "3. VUELO / FLIGHT", y: currentY, width: contentWidth)
            currentY += 20
            let flightInfo = """
            Vuelo / Flight: \(flight.displayFlightNumber)
            Fecha / Date: \(flight.scheduledDeparture.formatted(date: .long, time: .omitted))
            Ruta / Route: \(flight.departureAirport.code) ➝ \(flight.arrivalAirport.code)
            """
            _ = drawBodyText(text: flightInfo, y: currentY, width: contentWidth)
            currentY += 60
            
            // --- CONSOLIDATED LEGAL TEXT ---
            drawSectionHeader(text: "4. OBJETO Y ALCANCE / OBJECT AND SCOPE", y: currentY, width: contentWidth)
            currentY += 20
            
            // This is the key change: Representation + Fund Assignment (Collection) in one block
            let legalText = """
            Por medio del presente documento, el Otorgante AUTORIZA expresamente a la Entidad Autorizada para:
            
            1. REPRESENTACIÓN: Actuar en su nombre ante cualquier compañía aérea y ante la Agencia Estatal de Seguridad Aérea (AESA) para reclamar compensaciones derivadas del Reglamento (CE) 261/2004.
            
            2. CESIÓN DE COBRO: Solicitar y recibir, en su nombre y representación, cualquier cantidad económica reconocida o abonada por la compañía aérea. Se autoriza expresamente que el pago se realice en la cuenta bancaria designada por la Entidad Autorizada.
            
            3. TRÁMITES: Presentar escritos, recibir notificaciones y realizar cualquier gestión administrativa o extrajudicial necesaria.
            
            By this document, the Grantor expressly AUTHORIZES the Authorized Entity to:
            1. REPRESENTATION: Act on their behalf before any airline and the Spanish Aviation Safety Agency (AESA).
            2. COLLECTION ASSIGNMENT: Request and receive, on their behalf, any compensation amount. It is expressly authorized that payment be made to the bank account designated by the Authorized Entity.
            """
            
            let textHeight = drawBodyText(text: legalText, y: currentY, width: contentWidth)
            currentY += textHeight + 20
            
            // --- SIGNATURE ---
            drawSectionHeader(text: "5. FIRMA / SIGNATURE", y: currentY, width: contentWidth)
            currentY += 30
            
            let dateString = Date().formatted(date: .numeric, time: .shortened)
            let signLabel = "Firmado en (App) / Signed in (App): \(dateString)"
            _ = drawBodyText(text: signLabel, y: currentY, width: contentWidth)
            currentY += 20
            
            // Draw Signature Box
            let signatureRect = CGRect(x: margin, y: currentY, width: 250, height: 100)
            let boxPath = UIBezierPath(rect: signatureRect)
            UIColor.lightGray.setStroke()
            boxPath.lineWidth = 1.0
            boxPath.stroke()
            
            // Draw Actual Signature
            signature.draw(in: signatureRect.insetBy(dx: 10, dy: 10))
            
            currentY += 110
            let nameUnderSign = "\(userProfile.firstName) \(userProfile.lastName) (Otorgante)"
            _ = drawBodyText(text: nameUnderSign, y: currentY, width: contentWidth)
            
            // --- FOOTER ---
            let footerText = "Generado digitalmente por Flighty Compensation / Digitally generated"
            let footerAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 9),
                .paragraphStyle: centeredParagraphStyle(),
                .foregroundColor: UIColor.gray
            ]
            footerText.draw(in: CGRect(x: margin, y: pageHeight - 40, width: contentWidth, height: 20), withAttributes: footerAttributes)
        }
        
        return data
    }
    
    /// Generates a simple Complaint Letter to the Airline (Not signed, just a formal notice)
    func generateAirlineComplaintPDF(userProfile: UserProfile, flight: Flight) throws -> Data {
        let title = "SOLICITUD DE COMPENSACIÓN / COMPENSATION CLAIM"
        
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = [kCGPDFContextCreator: "FlightCompensation App"] as [String: Any]
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 595.2, height: 841.8), format: format)
        
        return renderer.pdfData { (context) in
            context.beginPage()
            let margin: CGFloat = 50.0
            
            let header = """
            TO: \(flight.airline.name)
            DATE: \(Date().formatted(date: .long, time: .omitted))
            
            RE: FORMAL CLAIM FOR COMPENSATION (EC 261/2004)
            """
            
            let body = """
            Dear Sir/Madam,
            
            I hereby claim compensation for flight \(flight.displayFlightNumber) on \(flight.scheduledDeparture.formatted(date: .numeric, time: .omitted)), which was \(flight.currentStatus == .cancelled ? "Cancelled" : "Delayed").
            
            Passenger: \(userProfile.firstName) \(userProfile.lastName)
            Booking Ref: [BOOKING_REF]
            
            In accordance with Regulation (EC) 261/2004, I am entitled to compensation.
            
            PLEASE NOTE:
            I have authorized Flighty Legal Services S.L. to represent me and manage the collection of this claim.
            
            PLEASE MAKE PAYMENT TO THE FOLLOWING ACCOUNT:
            Beneficiary: Flighty Legal Services S.L.
            IBAN: ES99 0000 1111 2222 3333
            SWIFT/BIC: FLIGHTYXX
            
            Attached is the 'Master Authorization' document signed by me confirming this instruction.
            
            Sincerely,
            
            \(userProfile.firstName) \(userProfile.lastName)
            """
            
            // Draw Header
            header.draw(in: CGRect(x: margin, y: 50, width: 500, height: 100), withAttributes: [
                .font: UIFont.boldSystemFont(ofSize: 12),
                .paragraphStyle: {
                    let s = NSMutableParagraphStyle()
                    s.alignment = .left
                    return s
                }()
            ])
            
            // Draw Body
            body.draw(in: CGRect(x: margin, y: 160, width: 500, height: 600), withAttributes: [
                .font: UIFont.systemFont(ofSize: 11)
            ])
        }
    }
    
    // MARK: - Helpers
    
    private func drawSectionHeader(text: String, y: CGFloat, width: CGFloat) {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 12),
            .paragraphStyle: leftParagraphStyle(),
            .backgroundColor: UIColor(white: 0.9, alpha: 1.0)
        ]
        // Draw background strip
        // let rect = CGRect(x: 50, y: y, width: width, height: 16)
        // context.fill(rect) ... logic simplified for swiftui renderer
        
        text.draw(in: CGRect(x: 50, y: y, width: width, height: 16), withAttributes: attributes)
    }
    
    private func drawBodyText(text: String, y: CGFloat, width: CGFloat) -> CGFloat {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10),
            .paragraphStyle: justifiedParagraphStyle()
        ]
        
        let rect = text.boundingRect(with: CGSize(width: width, height: .infinity), options: .usesLineFragmentOrigin, attributes: attributes, context: nil)
        
        text.draw(in: CGRect(x: 50, y: y, width: width, height: rect.height), withAttributes: attributes)
        
        return rect.height
    }
    
    private func drawLine(context: CGContext, from: CGPoint, to: CGPoint) {
        context.move(to: from)
        context.addLine(to: to)
        context.setStrokeColor(UIColor.black.cgColor)
        context.setLineWidth(1.0)
        context.strokePath()
    }
    
    private func centeredParagraphStyle() -> NSMutableParagraphStyle {
        let style = NSMutableParagraphStyle()
        style.alignment = .center
        return style
    }
    
    private func justifiedParagraphStyle() -> NSMutableParagraphStyle {
        let style = NSMutableParagraphStyle()
        style.alignment = .justified
        return style
    }
    
    private func leftParagraphStyle() -> NSMutableParagraphStyle {
        let style = NSMutableParagraphStyle()
        style.alignment = .left
        return style
    }
}
