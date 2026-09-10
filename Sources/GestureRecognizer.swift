import Foundation

enum Direction: String, CaseIterable { case left, right, up, down }
enum MouseInput { case down(Int), up(Int), move(Double, Double), other }

enum GestureTrigger: String, CaseIterable {
    case dragLeft, dragRight, dragUp, dragDown
    case leftHoldRightClick, leftHoldRightDoubleClick
    case rightHoldLeftClick, rightHoldLeftDoubleClick
    case leftRightLeftRight
    case rightLeftRightLeft
    case middleScrollUp, middleScrollDown
}

struct Decision {
    var consume = false
    var flush = false
    var discard = false
    var trigger: GestureTrigger?
}

/// Recognizes the four-direction chord and held-button click/double-click chords.
final class GestureRecognizer {
    private enum RepeatStyle { case single, double }
    private let chordWindow = 0.230
    private let doubleClickWindow = 0.280
    // Two physical buttons take longer to press and release together than a
    // conventional single-button double click. Keep this comfortably close to
    // macOS's normal double-click feel without slowing held-button clicks.
    private let bothButtonsDoubleClickWindow = 0.550
    private let movementThreshold = 35.0
    private let preChordMovementTolerance = 20.0
    private(set) var pressed: Set<Int> = []
    private var pending: (button: Int, time: Double)?
    private var chord = false
    private var primary = -1
    private var secondary = -1
    private var waitingRepeat: Double?
    private var repeatStyle: RepeatStyle?
    private var doubleCycleStarted = false
    private var bothTapStartedAt: Double?
    private var secondChordTap = false
    private var firstChordPrimary = -1
    private var fired = false
    private var x = 0.0
    private var y = 0.0

    var waiting: Bool { pending != nil }
    var idle: Bool { pressed.isEmpty && pending == nil && !chord }

    func expire(now: Double) -> Decision {
        var result = Decision()
        if let pending, now - pending.time >= chordWindow { self.pending = nil; result.flush = true }
        if let repeatTime = waitingRepeat, now - repeatTime >= doubleClickWindow {
            waitingRepeat = nil
            if repeatStyle != .double { fireSingle(&result) }
        }
        if let bothTapStartedAt, now - bothTapStartedAt >= bothButtonsDoubleClickWindow {
            self.bothTapStartedAt = nil
        }
        return result
    }

    func handle(_ input: MouseInput, now: Double) -> Decision {
        var result = expire(now: now)
        switch input {
        case .down(let button) where button == 0 || button == 1:
            let wasEmpty = pressed.isEmpty
            pressed.insert(button)
            if chord {
                if button == secondary, pressed.contains(primary) {
                    result.consume = true
                    if waitingRepeat != nil {
                        waitingRepeat = nil; fired = true; repeatStyle = .double; doubleCycleStarted = false
                        result.trigger = clickTrigger(double: true)
                    } else if repeatStyle == .single {
                        result.trigger = clickTrigger(double: false)
                    } else if repeatStyle == .double {
                        doubleCycleStarted = true
                    }
                } else { result.consume = true }
            } else if let pending, pending.button != button {
                let secondChordPrimary = pending.button
                beginChord(primary: secondChordPrimary, secondary: button)
                result.consume = true; result.discard = true
                if secondChordTap {
                    fired = true; secondChordTap = false
                    result.trigger = orderedDoubleTrigger(first: firstChordPrimary, second: secondChordPrimary)
                }
            } else if wasEmpty {
                secondChordTap = bothTapStartedAt != nil
                bothTapStartedAt = nil
                pending = (button, now); x = 0; y = 0; result.consume = true
            } else if pressed.count == 2 {
                beginChord(primary: pressed.first(where: { $0 != button }) ?? 0, secondary: button)
                result.consume = true
            }
        case .up(let button) where button == 0 || button == 1:
            pressed.remove(button)
            if chord {
                result.consume = true
                if pressed.isEmpty, !fired, repeatStyle == nil {
                    waitingRepeat = nil; chord = false; bothTapStartedAt = now; firstChordPrimary = primary; secondChordTap = false
                    return result
                }
                if button == secondary, pressed.contains(primary) {
                    if !fired { waitingRepeat = now }
                    else if repeatStyle == .double, doubleCycleStarted { waitingRepeat = now; doubleCycleStarted = false }
                }
                if button == primary, waitingRepeat != nil, repeatStyle != .double { waitingRepeat = nil; fireSingle(&result) }
                if pressed.isEmpty {
                    if waitingRepeat != nil, repeatStyle != .double { waitingRepeat = nil; fireSingle(&result) }
                    waitingRepeat = nil
                    chord = false
                }
            } else if pending != nil {
                // A normal short click must be replayed as a matching pair.
                // The engine buffers this mouse-up before flushing the held
                // mouse-down, instead of mixing a synthetic down with the
                // original up event.
                pending = nil; result.consume = true; result.flush = true
            }
        case .move(let dx, let dy):
            if chord {
                result.consume = true
                guard !fired, waitingRepeat == nil else { return result }
                x += dx; y += dy
                if max(abs(x), abs(y)) >= movementThreshold {
                    fired = true
                    result.trigger = abs(x) >= abs(y) ? (x < 0 ? .dragLeft : .dragRight) : (y < 0 ? .dragUp : .dragDown)
                }
            } else if pending != nil {
                x += dx; y += dy
                if hypot(x, y) >= preChordMovementTolerance {
                    // Replay the current drag with the buffered down event so
                    // web controls observe one consistent event sequence.
                    pending = nil; result.consume = true; result.flush = true
                } else { result.consume = true }
            }
        default:
            if pending != nil { pending = nil; result.flush = true }
        }
        return result
    }

    private func beginChord(primary: Int, secondary: Int) {
        pending = nil; chord = true; self.primary = primary; self.secondary = secondary
        waitingRepeat = nil; repeatStyle = nil; doubleCycleStarted = false; fired = false; x = 0; y = 0
    }
    private func fireSingle(_ result: inout Decision) {
        fired = true; repeatStyle = .single; result.trigger = clickTrigger(double: false)
    }
    private func clickTrigger(double: Bool) -> GestureTrigger {
        if primary == 0 { return double ? .leftHoldRightDoubleClick : .leftHoldRightClick }
        return double ? .rightHoldLeftDoubleClick : .rightHoldLeftClick
    }
    private func orderedDoubleTrigger(first: Int, second: Int) -> GestureTrigger? {
        if first == 0, second == 0 { return .leftRightLeftRight }
        if first == 1, second == 1 { return .rightLeftRightLeft }
        return nil
    }
}
