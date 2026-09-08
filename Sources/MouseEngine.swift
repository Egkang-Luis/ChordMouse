import Cocoa

final class MouseEngine {
    private var tap: CFMachPort?
    private var source: CFRunLoopSource?
    private var timer: Timer?
    private var recognizer = GestureRecognizer()
    private var buffered: [CGEvent] = []
    private var recoveringTap = false
    private let marker: Int64 = 0x43484F52444D
    private let executor: GestureExecutor
    private(set) var enabled = true
    var onGesture: ((Direction) -> Void)?
    /// Short, user-facing input milestones. This makes an event-tap or mouse-hardware
    /// issue distinguishable from a macOS shortcut configuration issue.
    var onInputStatus: ((String) -> Void)?
    var onFailure: (() -> Void)?
    var running: Bool { tap != nil }

    init(executor: GestureExecutor) {
        self.executor = executor
    }

    func start() -> Bool {
        guard tap == nil else { return true }
        guard AXIsProcessTrusted() else { return false }
        let types: [CGEventType] = [.leftMouseDown, .leftMouseUp, .rightMouseDown, .rightMouseUp,
            .mouseMoved, .leftMouseDragged, .rightMouseDragged, .otherMouseDown,
            .otherMouseUp, .otherMouseDragged, .scrollWheel]
        let mask = types.reduce(CGEventMask(0)) { $0 | (CGEventMask(1) << $1.rawValue) }
        guard let newTap = CGEvent.tapCreate(tap: .cgSessionEventTap, place: .headInsertEventTap,
            options: .defaultTap, eventsOfInterest: mask, callback: { proxy, type, event, info in
                guard let info else { return Unmanaged.passUnretained(event) }
                return Unmanaged<MouseEngine>.fromOpaque(info).takeUnretainedValue()
                    .handle(proxy: proxy, type: type, event: event)
            }, userInfo: Unmanaged.passUnretained(self).toOpaque()) else { return false }
        tap = newTap
        source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, newTap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: newTap, enable: true)
        let tick = Timer(timeInterval: 0.005, repeats: true) { [weak self] _ in
            guard let self else { return }
            let now = ProcessInfo.processInfo.systemUptime
            if self.recognizer.expire(now: now) { self.flush(proxy: nil) }
        }
        timer = tick
        RunLoop.main.add(tick, forMode: .common)
        return true
    }

    // A live chord is drained before pause takes effect, preventing unmatched button events.
    func setEnabled(_ value: Bool) { enabled = value }

    func restart() -> Bool {
        stop()
        return start()
    }

    func stop() {
        timer?.invalidate(); timer = nil
        flush(proxy: nil)
        if let tap { CGEvent.tapEnable(tap: tap, enable: false) }
        if let source { CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes) }
        if let tap { CFMachPortInvalidate(tap) }
        source = nil; tap = nil
        recognizer = GestureRecognizer()
    }

    private func flush(proxy: CGEventTapProxy?) {
        let events = buffered; buffered.removeAll(keepingCapacity: true)
        for event in events {
            event.setIntegerValueField(.eventSourceUserData, value: marker)
            // In callbacks, insert before the current event, preserving down/drag/up order.
            if let proxy { event.tapPostEvent(proxy) }
            else { event.post(tap: .cgSessionEventTap) }
        }
    }

    private func handle(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            // A disabled tap may have lost an up event. Drop all in-progress
            // input and rebuild the tap rather than keeping a stale port alive.
            recognizer = GestureRecognizer()
            buffered.removeAll(keepingCapacity: true)
            guard !recoveringTap else { return Unmanaged.passUnretained(event) }
            recoveringTap = true
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                let recovered = self.restart()
                self.recoveringTap = false
                if recovered {
                    self.onInputStatus?(AppText.tapReconnected)
                } else {
                    self.onFailure?()
                }
            }
            return Unmanaged.passUnretained(event)
        }
        if event.getIntegerValueField(.eventSourceUserData) == marker { return Unmanaged.passUnretained(event) }
        if !enabled && recognizer.idle { return Unmanaged.passUnretained(event) }
        let now = ProcessInfo.processInfo.systemUptime
        let input: MouseInput
        switch type {
        case .leftMouseDown: input = .down(0)
        case .rightMouseDown: input = .down(1)
        case .leftMouseUp: input = .up(0)
        case .rightMouseUp: input = .up(1)
        case .mouseMoved, .leftMouseDragged, .rightMouseDragged:
            input = .move(event.getDoubleValueField(.mouseEventDeltaX), event.getDoubleValueField(.mouseEventDeltaY))
        default: input = .other
        }
        let result = recognizer.handle(input, now: now)
        if result.flush { flush(proxy: proxy) }
        if result.discard { buffered.removeAll(keepingCapacity: true) }
        if result.consume && recognizer.waiting, let copy = event.copy() { buffered.append(copy) }
        if case .down(let button) = input, recognizer.waiting {
            DispatchQueue.main.async { [weak self] in
                self?.onInputStatus?(AppText.firstButton(button))
            }
        }
        if result.discard {
            DispatchQueue.main.async { [weak self] in
                self?.onInputStatus?(AppText.chordDetected)
            }
        }
        if let direction = result.direction {
            DispatchQueue.main.async { [weak self] in
                self?.executor.execute(direction)
                self?.onGesture?(direction)
                self?.onInputStatus?(AppText.gestureExecuted(direction))
            }
        }
        return result.consume ? nil : Unmanaged.passUnretained(event)
    }
}
