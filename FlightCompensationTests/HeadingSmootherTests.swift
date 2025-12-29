import XCTest
@testable import FlightCompensation

final class HeadingSmootherTests: XCTestCase {
    func testSmoothingReducesAbruptChangeAcrossZero() {
        let smoother = HeadingSmoother(alpha: 0.8)
        let h1 = smoother.update(with: 350)
        XCTAssertEqual(h1, 350)
        let h2 = smoother.update(with: 10) // abrupt change from 350 -> 10 should go through 0
        // Expect smoothed value to be near 350 + small positive delta (wrap-handling)
        XCTAssertGreaterThan(h2, 350)
        XCTAssertLessThan(h2, 360)
    }

    func testSmoothingConverges() {
        let smoother = HeadingSmoother(alpha: 0.5)
        var last = smoother.update(with: 0)
        for _ in 0..<10 {
            last = smoother.update(with: 90)
        }
        XCTAssertGreaterThan(last, 45)
        XCTAssertLessThan(last, 95)
    }
}
