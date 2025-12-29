import Foundation

/// Simple heading smoother using exponential moving average that correctly handles wrap-around across 0/360.
final class HeadingSmoother {
    private var smoothed: Double?
    private let alpha: Double

    init(alpha: Double = 0.7) {
        self.alpha = alpha
    }

    func update(with newHeading: Double) -> Double {
        // Normalize to 0-360
        var heading = newHeading.truncatingRemainder(dividingBy: 360)
        if heading < 0 { heading += 360 }

        guard let current = smoothed else {
            smoothed = heading
            return heading
        }

        // Compute shortest angular difference
        var delta = heading - current
        if delta > 180 { delta -= 360 }
        if delta < -180 { delta += 360 }

        let updated = current + (1 - alpha) * delta
        var normalized = updated.truncatingRemainder(dividingBy: 360)
        if normalized < 0 { normalized += 360 }
        smoothed = normalized
        return normalized
    }

    func reset() {
        smoothed = nil
    }
}
