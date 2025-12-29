import Foundation

extension Airline {
    
    /// Returns the best known email address for submitting claims to this airline.
    var claimEmail: String {
        switch code.uppercased() {
            // MARK: - Spanish & Major EU Airlines
        case "IB": return "reclamaciones@iberia.es"         // Iberia
        case "VY": return "contactus@vueling.com"           // Vueling (often replies from claims@vueling.com)
        case "UX": return "atencion.cliente@air-europa.com" // Air Europa
        case "I2": return "atencion.cliente@iberiaexpress.com" // Iberia Express
        case "YW": return "atencion.cliente@airnostrum.es"  // Air Nostrum
        case "V7": return "reclamaciones@volotea.com"       // Volotea
            
            // MARK: - International Majors operating in EU
        case "FR": return "customerqueries@ryanair.com"     // Ryanair (hard to reach via email, this is best bet)
        case "BA": return "customer.relations@ba.com"       // British Airways
        case "LH": return "customer.relations@lufthansa.com" // Lufthansa
        case "AF": return "mail.reclamations@airfrance.fr"  // Air France
        case "KL": return "customercare@klm.com"            // KLM
        case "U2": return "customer.support@easyjet.com"    // EasyJet
        case "LX": return "contactus@swiss.com"             // Swiss
        case "OS": return "customer.relations@austrian.com" // Austrian
        case "SN": return "customer.relations@brusselsairlines.com" // Brussels Airlines
        case "TP": return "customer.relations@tap.pt"       // TAP Portugal
        case "DY", "D8": return "claims@norwegian.com"      // Norwegian
        case "W6", "W9": return "info@wizzair.com"          // Wizz Air
            
            // MARK: - Expanded European List
        case "SK": return "contacttoflysas@sasair.com"      // SAS
        case "AY": return "contact.us@finnair.com"          // Finnair (Best effort)
        case "A3": return "contact@aegeanair.com"           // Aegean
        case "LO": return "passenger.claims@lot.pl"         // LOT Polish
        case "EI": return "guestrelations@aerlingus.com"    // Aer Lingus
        case "VS": return "customer.services@fly.virgin.com" // Virgin Atlantic
        case "LS": return "customer.service@jet2.com"       // Jet2
        case "HV", "TO": return "contact@transavia.com"     // Transavia
        case "EW": return "buchungsinfo@eurowings.com"      // Eurowings
        case "DE": return "kundenbetreuung@condor.com"      // Condor
        case "LG": return "customer.relations@luxair.lu"    // Luxair
        case "NT": return "atencionclientes@bintercanarias.com" // Binter Canarias
        case "AZ": return "bookingschangesrefunds@ita-airways.com" // ITA Airways
        case "KM": return "customercare.airmalta@km.com.mt" // Air Malta
        case "QS": return "info@smartwings.com"             // Smartwings
        case "BT": return "relations@airbaltic.com"         // Air Baltic
        case "JU": return "customer.relations@airserbia.com" // Air Serbia
        case "RO": return "customer.service@tarom.ro"       // Tarom
        case "OU": return "contact@croatiaairlines.hr"      // Croatia Airlines
        case "FB": return "feedback@air.bg"                 // Bulgaria Air
            
            // MARK: - Non-EU (for return flights)
        case "AA": return "customer.relations@aa.com"       // American Airlines
        case "DL": return "ticketreceipt@delta.com"         // Delta (often separate process, but valid start)
        case "UA": return "customercare@united.com"         // United
        case "EK": return "customer.affairs@emirates.com"   // Emirates
        case "QR": return "tell-us@qatarairways.com.qa"     // Qatar Airways
        case "TK": return "customer.solutions@thy.com"      // Turkish Airlines
        case "AT": return "callcenter@royalairmaroc.com"    // Royal Air Maroc
            
            // MARK: - Fallback
        default:
            // Attempt to guess based on name, but default to a "claims@" pattern
            let sanitizedName = name.lowercased()
                .replacingOccurrences(of: " ", with: "")
                .replacingOccurrences(of: "airlines", with: "")
                .replacingOccurrences(of: "airways", with: "")
            return "claims@\(sanitizedName).com"
        }
    }
}
