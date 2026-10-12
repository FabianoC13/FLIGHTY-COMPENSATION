import XCTest
@testable import EU261Core

final class EU261RulesTests: XCTestCase {

    private static let db: AirportDatabase = {
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("FlightCompensation/Resources/airports.json")
        return try! AirportDatabase(jsonData: Data(contentsOf: url))
    }()

    private func input(_ dep: String, _ arr: String, carrier: String, _ disruption: EU261Input.Disruption, reason: String? = nil) -> EU261Input {
        let d = Self.db.lookup(dep), a = Self.db.lookup(arr)
        var distance: Double?
        if let d, let a {
            distance = AirportDatabase.greatCircleDistanceKm(lat1: d.latitude, lon1: d.longitude, lat2: a.latitude, lon2: a.longitude)
        }
        return EU261Input(departureIATA: dep, arrivalIATA: arr, departureCountry: d?.countryCode, arrivalCountry: a?.countryCode,
                          distanceKm: distance, operatingCarrier: carrier, disruption: disruption, reportedReason: reason)
    }

    private func delay(_ hours: Double) -> EU261Input.Disruption { .delay(arrivalDelayMinutes: Int(hours * 60)) }

    // MARK: Airport data

    func testAirportDatabaseCoversMostAirports() {
        XCTAssertGreaterThan(Self.db.count, 8000)
        for code in ["MAD", "BCN", "LPA", "FNC", "PDL", "RUN", "JFK", "DXB", "SIN", "KEF", "ZRH", "BOG", "EZE"] {
            XCTAssertNotNil(Self.db.lookup(code), code)
        }
    }

    func testDistances() {
        XCTAssertEqual(input("MAD", "FRA", carrier: "IB", delay(4)).distanceKm!, 1420, accuracy: 30)
        XCTAssertEqual(input("LHR", "JFK", carrier: "BA", delay(4)).distanceKm!, 5540, accuracy: 30)
    }

    // MARK: Amounts (Art. 7)

    func testShortHaulDelay() {
        let r = EU261Rules.assess(input("MAD", "CDG", carrier: "IB", delay(3.2)))
        XCTAssertEqual(r.outcome, .eligible)
        XCTAssertEqual(r.amount, 250)
        XCTAssertEqual(r.currency, "EUR")
    }

    func testMediumHaulDelay() {
        let r = EU261Rules.assess(input("MAD", "ATH", carrier: "UX", delay(5)))
        XCTAssertEqual(r.amount, 400)
    }

    func testLongHaulDelayOverFourHoursPays600() {
        let r = EU261Rules.assess(input("MAD", "JFK", carrier: "IB", delay(4.5)))
        XCTAssertEqual(r.amount, 600)
    }

    func testLongHaulDelayBetweenThreeAndFourHoursPays300() {
        let r = EU261Rules.assess(input("MAD", "JFK", carrier: "IB", delay(3.5)))
        XCTAssertEqual(r.outcome, .eligible)
        XCTAssertEqual(r.amount, 300)
    }

    func testIntraEUOver3500kmIsCappedAt400() {
        // Helsinki → Gran Canaria is ~4,700 km but both airports are in the EU.
        let r = EU261Rules.assess(input("HEL", "LPA", carrier: "AY", delay(6)))
        XCTAssertGreaterThan(r.distanceKm!, 3500)
        XCTAssertEqual(r.amount, 400)
        // ... and the 3-4h long-haul reduction doesn't apply to it either.
        XCTAssertEqual(EU261Rules.assess(input("HEL", "LPA", carrier: "AY", delay(3.5))).amount, 400)
    }

    func testDelayUnderThreeHoursNotEligible() {
        let r = EU261Rules.assess(input("MAD", "CDG", carrier: "IB", delay(2.9)))
        XCTAssertEqual(r.outcome, .notEligible)
        XCTAssertEqual(r.amount, 0)
    }

    func testExactlyThreeHoursIsEligible() {
        XCTAssertEqual(EU261Rules.assess(input("MAD", "CDG", carrier: "IB", .delay(arrivalDelayMinutes: 180))).outcome, .eligible)
    }

    func testUnknownDelayNeedsInformation() {
        let r = EU261Rules.assess(input("MAD", "CDG", carrier: "IB", .delay(arrivalDelayMinutes: nil)))
        XCTAssertEqual(r.outcome, .needsInformation)
        XCTAssertEqual(r.missing, [.arrivalDelay])
    }

    // MARK: Scope (Art. 3)

    func testNonEUAirlineDepartingEUIsCovered() {
        XCTAssertEqual(EU261Rules.assess(input("ZRH", "JFK", carrier: "UA", delay(5))).regime, .eu261)
        XCTAssertEqual(EU261Rules.assess(input("MAD", "JFK", carrier: "DL", delay(5))).regime, .eu261)
    }

    func testEUAirlineArrivingInEUIsCovered() {
        let r = EU261Rules.assess(input("JFK", "MAD", carrier: "IB", delay(5)))
        XCTAssertEqual(r.regime, .eu261)
        XCTAssertEqual(r.amount, 600)
    }

    func testNonEUAirlineArrivingInEUIsNotCovered() {
        XCTAssertEqual(EU261Rules.assess(input("JFK", "MAD", carrier: "DL", delay(5))).outcome, .notEligible)
        // UK carriers are no longer Community carriers.
        XCTAssertEqual(EU261Rules.assess(input("JFK", "MAD", carrier: "BA", delay(5))).outcome, .notEligible)
    }

    func testEUAirlineBetweenNonEUAirportsIsNotCovered() {
        XCTAssertEqual(EU261Rules.assess(input("DXB", "JFK", carrier: "LH", delay(5))).outcome, .notEligible)
        XCTAssertEqual(EU261Rules.assess(input("JFK", "MEX", carrier: "IB", delay(5))).outcome, .notEligible)
    }

    func testOutermostRegionsAreEU() {
        XCTAssertEqual(EU261Rules.assess(input("PTP", "ORY", carrier: "TX", delay(5))).regime, .eu261)
        XCTAssertEqual(EU261Rules.assess(input("FNC", "LIS", carrier: "TP", delay(5))).regime, .eu261)
    }

    func testFaroeIslandsAreNotEU() {
        XCTAssertEqual(EU261Rules.assess(input("FAE", "CPH", carrier: "RC", delay(5))).outcome, .notEligible)
    }

    func testUK261() {
        let fromUK = EU261Rules.assess(input("LHR", "JFK", carrier: "BA", delay(5)))
        XCTAssertEqual(fromUK.regime, .uk261)
        XCTAssertEqual(fromUK.currency, "GBP")
        XCTAssertEqual(fromUK.amount, 520)
        XCTAssertEqual(EU261Rules.assess(input("LHR", "JFK", carrier: "BA", delay(3.5))).amount, 260)
        XCTAssertEqual(EU261Rules.assess(input("JFK", "LHR", carrier: "BA", delay(5))).regime, .uk261)
        XCTAssertEqual(EU261Rules.assess(input("JFK", "LHR", carrier: "DL", delay(5))).outcome, .notEligible)
        // UK → EU on an EU airline: EU261 applies.
        XCTAssertEqual(EU261Rules.assess(input("LHR", "MAD", carrier: "IB", delay(5))).regime, .eu261)
        // EU → UK on any airline: EU261.
        XCTAssertEqual(EU261Rules.assess(input("MAD", "LHR", carrier: "BA", delay(5))).regime, .eu261)
    }

    // MARK: Cancellations (Art. 5)

    func testCancellationWith14DaysNoticeNotEligible() {
        let info = EU261Input.CancellationInfo(noticeDaysBeforeDeparture: 20, reroutingAnswered: true, rerouting: nil)
        XCTAssertEqual(EU261Rules.assess(input("MAD", "CDG", carrier: "IB", .cancellation(info))).outcome, .notEligible)
    }

    func testCancellationShortNoticeNoReroutingEligible() {
        let info = EU261Input.CancellationInfo(noticeDaysBeforeDeparture: 2, reroutingAnswered: true, rerouting: nil)
        let r = EU261Rules.assess(input("MAD", "JFK", carrier: "IB", .cancellation(info)))
        XCTAssertEqual(r.outcome, .eligible)
        XCTAssertEqual(r.amount, 600)
    }

    func testCancellationWithCloseReroutingExempt() {
        // < 7 days, alternative leaves 30 min earlier and arrives 90 min later → exempt.
        let short = EU261Input.CancellationInfo(noticeDaysBeforeDeparture: 3, reroutingAnswered: true,
                                                rerouting: .init(departedEarlierByMinutes: 30, arrivedLaterByMinutes: 90))
        XCTAssertEqual(EU261Rules.assess(input("MAD", "CDG", carrier: "IB", .cancellation(short))).outcome, .notEligible)
        // 7–13 days, alternative leaves 2h earlier and arrives 3h later → exempt.
        let mid = EU261Input.CancellationInfo(noticeDaysBeforeDeparture: 10, reroutingAnswered: true,
                                              rerouting: .init(departedEarlierByMinutes: 120, arrivedLaterByMinutes: 180))
        XCTAssertEqual(EU261Rules.assess(input("MAD", "CDG", carrier: "IB", .cancellation(mid))).outcome, .notEligible)
    }

    func testCancellationReroutingReduction() {
        // < 7 days, alternative arrives 2h30 late on a long-haul (> 3,500 km): not exempt, but ≤ 4h → 50 %.
        let info = EU261Input.CancellationInfo(noticeDaysBeforeDeparture: 1, reroutingAnswered: true,
                                               rerouting: .init(departedEarlierByMinutes: 0, arrivedLaterByMinutes: 150))
        let r = EU261Rules.assess(input("MAD", "JFK", carrier: "IB", .cancellation(info)))
        XCTAssertEqual(r.outcome, .eligible)
        XCTAssertEqual(r.amount, 300)
        // Same on a short-haul arriving 5h late → full amount.
        let late = EU261Input.CancellationInfo(noticeDaysBeforeDeparture: 1, reroutingAnswered: true,
                                               rerouting: .init(departedEarlierByMinutes: 0, arrivedLaterByMinutes: 300))
        XCTAssertEqual(EU261Rules.assess(input("MAD", "CDG", carrier: "IB", .cancellation(late))).amount, 250)
    }

    func testCancellationUnknownNoticeNeedsInformation() {
        let r = EU261Rules.assess(input("MAD", "CDG", carrier: "IB", .cancellation(.init())))
        XCTAssertEqual(r.outcome, .needsInformation)
        XCTAssertTrue(r.missing.contains(.cancellationNotice))
    }

    // MARK: Extraordinary circumstances

    func testWeatherIsFlagged() {
        let r = EU261Rules.assess(input("MAD", "CDG", carrier: "IB", delay(4), reason: "Bad weather at destination"))
        XCTAssertEqual(r.outcome, .eligible)
        XCTAssertFalse(r.warnings.isEmpty)
        XCTAssertLessThanOrEqual(r.confidence, 0.6)
    }

    func testTechnicalProblemIsNotFlagged() {
        XCTAssertTrue(EU261Rules.assess(input("MAD", "CDG", carrier: "IB", delay(4), reason: "Technical issue")).warnings.isEmpty)
        XCTAssertNil(EU261Rules.extraordinaryCircumstancesWarning(for: "Waiting for a matching gate slot"))
    }

    func testUnknownAirport() {
        let r = EU261Rules.assess(input("XQZ", "CDG", carrier: "IB", delay(4)))
        XCTAssertEqual(r.outcome, .needsInformation)
        XCTAssertEqual(r.missing, [.airportData])
    }
}
