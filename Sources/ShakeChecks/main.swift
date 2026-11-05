import CoreGraphics
import Foundation
import ShakeCore

var failures = 0

func check(_ name: String, _ passed: Bool) {
    print("\(passed ? "ok  " : "FAIL") \(name)")
    if !passed { failures += 1 }
}

/// Moves between the given x positions in small steps and reports whether a shake fired.
func run(_ stops: [CGFloat], secondsPerStop: TimeInterval, jitter: CGFloat = 0, sensitivity: ShakeSensitivity = .medium) -> Bool {
    var detector = ShakeDetector(sensitivity: sensitivity)
    var time: TimeInterval = 0
    var previous = stops[0]
    var fired = false
    for stop in stops.dropFirst() {
        for step in 1...10 {
            let wobble = step.isMultiple(of: 2) ? jitter : -jitter
            let x = previous + (stop - previous) * CGFloat(step) / 10 + wobble
            time += secondsPerStop / 10
            if detector.add(CGPoint(x: x, y: 100), at: time) { fired = true }
        }
        previous = stop
    }
    return fired
}

check("quick shake fires", run([0, 100, 0, 100, 0], secondsPerStop: 0.12))
check("straight drag does not fire", !run([0, 800], secondsPerStop: 1))
check("slow back and forth does not fire", !run([0, 100, 0, 100, 0], secondsPerStop: 1))
check("jitter on a straight drag does not fire", !run([0, 800], secondsPerStop: 1, jitter: 10))

var vertical = ShakeDetector()
var verticalFired = false
for (index, y) in ([0, 100, 0, 100, 0] as [CGFloat]).enumerated() {
    if vertical.add(CGPoint(x: 50, y: y), at: Double(index) * 0.1) { verticalFired = true }
}
check("vertical shake fires", verticalFired)

var interrupted = ShakeDetector()
_ = interrupted.add(CGPoint(x: 0, y: 0), at: 0)
_ = interrupted.add(CGPoint(x: 100, y: 0), at: 0.1)
_ = interrupted.add(CGPoint(x: 0, y: 0), at: 0.2)
_ = interrupted.add(CGPoint(x: 100, y: 0), at: 0.3)
interrupted.reset()
check("reset clears progress", !interrupted.add(CGPoint(x: 0, y: 0), at: 0.4))

let smallShake: [CGFloat] = [0, 35, 0, 35, 0]
check("small shake fires on high", run(smallShake, secondsPerStop: 0.1, sensitivity: .high))
check("small shake does not fire on medium", !run(smallShake, secondsPerStop: 0.1, sensitivity: .medium))
let shortShake: [CGFloat] = [0, 100, 0, 100, 0]
check("short shake does not fire on low", !run(shortShake, secondsPerStop: 0.1, sensitivity: .low))
check("longer shake fires on low", run(shortShake + [100, 0], secondsPerStop: 0.1, sensitivity: .low))
check("straight drag does not fire on high", !run([0, 800], secondsPerStop: 1, jitter: 10, sensitivity: .high))

exit(failures == 0 ? 0 : 1)
