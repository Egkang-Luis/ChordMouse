import Foundation

enum Direction: String, CaseIterable { case left, right, up, down }
enum MouseInput { case down(Int), up(Int), move(Double, Double), other }
struct Decision {
    var consume = false
    var flush = false
    var discard = false
    var direction: Direction?
}

/// Pure state machine; no global input or keyboard output. All calls use one serial run loop.
final class GestureRecognizer {
    // Fixed to the former “5 · very high” profile. It accommodates ordinary
    // two-button mouse switch timing and small hand movement before the chord.
    private let chordWindow: Double = 0.230
    private let preChordMovementTolerance: Double = 20
    private let threshold: Double = 35
    private(set) var pressed: Set<Int> = []
    private var pending: (button: Int, time: Double)?
    private var chord = false
    private var released = false
    private var fired = false
    private var x = 0.0
    private var y = 0.0
    var waiting: Bool { pending != nil }
    var idle: Bool { pressed.isEmpty && pending == nil && !chord }

    func expire(now: Double) -> Bool {
        guard let p = pending, now - p.time >= chordWindow else { return false }
        pending = nil
        return true
    }

    func handle(_ input: MouseInput, now: Double) -> Decision {
        var result = Decision(flush: expire(now: now))
        switch input {
        case .down(let button):
            let wasEmpty = pressed.isEmpty
            pressed.insert(button)
            if chord { result.consume = true; return result }
            if let p = pending, p.button != button {
                pending = nil; chord = true; released = false; fired = false
                x = 0; y = 0
                result.consume = true; result.discard = true
            } else if wasEmpty {
                pending = (button, now); x = 0; y = 0
                result.consume = true
            }
        case .up(let button):
            pressed.remove(button)
            if chord {
                result.consume = true; released = true
                if pressed.isEmpty { chord = false }
            } else if pending != nil {
                pending = nil; result.flush = true
            }
        case .move(let dx, let dy):
            if chord {
                result.consume = true
                if !released && !fired {
                    x += dx; y += dy
                    if max(abs(x), abs(y)) >= threshold {
                        fired = true
                        result.direction = abs(x) >= abs(y) ? (x < 0 ? .left : .right) : (y < 0 ? .up : .down)
                    }
                }
            } else if pending != nil {
                x += dx; y += dy
                if hypot(x, y) >= preChordMovementTolerance {
                    pending = nil; result.flush = true
                } else { result.consume = true }
            }
        case .other:
            // Preserve order around scroll/middle-button input and abandon chord candidacy.
            if pending != nil { pending = nil; result.flush = true }
        }
        return result
    }
}
