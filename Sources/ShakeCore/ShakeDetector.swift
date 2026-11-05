import CoreGraphics
import Foundation

/// How readily a shake is recognized.
public enum ShakeSensitivity: String, CaseIterable {
    case low, medium, high
}

/// Detects a shake gesture from a stream of cursor positions.
///
/// Each axis is tracked separately. A reversal only counts once the cursor has moved
/// `minTravel` points back from its furthest point, so hand jitter is ignored.
public struct ShakeDetector {
    private struct Axis {
        var anchor: CGFloat?
        var direction: CGFloat = 0
        var extreme: CGFloat = 0

        /// Returns true when this position completes a reversal.
        mutating func add(_ value: CGFloat, minTravel: CGFloat) -> Bool {
            guard let anchor else {
                self.anchor = value
                return false
            }
            if direction == 0 {
                if abs(value - anchor) >= minTravel {
                    direction = value > anchor ? 1 : -1
                    extreme = value
                }
                return false
            }
            if (value - extreme) * direction > 0 {
                extreme = value
                return false
            }
            if abs(value - extreme) >= minTravel {
                direction = -direction
                extreme = value
                return true
            }
            return false
        }
    }

    private let minTravel: CGFloat
    private let requiredReversals: Int
    private let window: TimeInterval
    private var x = Axis()
    private var y = Axis()
    private var xReversals: [TimeInterval] = []
    private var yReversals: [TimeInterval] = []

    public init(minTravel: CGFloat = 40, requiredReversals: Int = 3, window: TimeInterval = 0.7) {
        self.minTravel = minTravel
        self.requiredReversals = requiredReversals
        self.window = window
    }

    public init(sensitivity: ShakeSensitivity) {
        switch sensitivity {
        case .low: self.init(minTravel: 60, requiredReversals: 4, window: 0.8)
        case .medium: self.init()
        case .high: self.init(minTravel: 25, requiredReversals: 3, window: 0.7)
        }
    }

    public mutating func reset() {
        x = Axis()
        y = Axis()
        xReversals = []
        yReversals = []
    }

    /// Feeds a cursor position and returns true when a shake has just been completed.
    public mutating func add(_ point: CGPoint, at time: TimeInterval) -> Bool {
        if x.add(point.x, minTravel: minTravel) { xReversals.append(time) }
        if y.add(point.y, minTravel: minTravel) { yReversals.append(time) }
        xReversals.removeAll { time - $0 > window }
        yReversals.removeAll { time - $0 > window }

        guard xReversals.count >= requiredReversals || yReversals.count >= requiredReversals else {
            return false
        }
        reset()
        return true
    }
}
