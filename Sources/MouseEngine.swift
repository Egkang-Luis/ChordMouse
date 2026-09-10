import Cocoa

final class MouseEngine {
    private var tap: CFMachPort?
    private var source: CFRunLoopSource?
    private var timer: Timer?
    private var recognizer = GestureRecognizer()
    private var buffered: [CGEvent] = []
    private var recoveringTap = false
    private let marker: Int64 = 0x43484F52444D
    private let executor: KeyboardGestureExecutor
    private let settings: GestureSettings
    private var middleHeld = false
    private(set) var enabled = true
    var onGesture: ((GestureTrigger, GestureAction) -> Void)?
    /// Short, user-facing input milestones. This makes an event-tap or mouse-hardware
    /// issue distinguishable from a macOS shortcut configuration issue.
    var onInputStatus: ((String) -> Void)?
    var onFailure: (() -> Void)?
    var running: Bool { tap != nil }

    init(executor: KeyboardGestureExecutor, settings: GestureSettings) {
        self.executor = executor
        self.settings = settings
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
            self.apply(self.recognizer.expire(now: now), proxy: nil)
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
        middleHeld = false
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
            // Do not lose a normal click that was waiting for a possible
            // chord when macOS temporarily disables this event tap.
            flush(proxy: nil)
            recognizer = GestureRecognizer()
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
        if type == .otherMouseDown, event.getIntegerValueField(.mouseEventButtonNumber) == 2 {
            middleHeld = true
            return Unmanaged.passUnretained(event)
        }
        if type == .otherMouseUp, event.getIntegerValueField(.mouseEventButtonNumber) == 2 {
            middleHeld = false
            return Unmanaged.passUnretained(event)
        }
        if type == .scrollWheel, middleHeld {
            let delta = event.getDoubleValueField(.scrollWheelEventDeltaAxis1)
            if delta != 0 {
                fire(delta > 0 ? .middleScrollUp : .middleScrollDown)
                return nil
            }
        }
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
        // Keep each event that has actually been held back while deciding
        // whether a second button will form a chord. Chord input is discarded
        // separately below.
        let wasWaiting = recognizer.waiting
        let result = recognizer.handle(input, now: now)
        if result.consume, !result.discard, wasWaiting || recognizer.waiting,
           let copy = event.copy() {
            buffered.append(copy)
        }
        apply(result, proxy: proxy)
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
        return result.consume ? nil : Unmanaged.passUnretained(event)
    }

    private func apply(_ result: Decision, proxy: CGEventTapProxy?) {
        if result.flush { flush(proxy: proxy) }
        if result.discard { buffered.removeAll(keepingCapacity: true) }
        if let trigger = result.trigger { fire(trigger) }
    }

    private func fire(_ trigger: GestureTrigger) {
        let action = settings.action(for: trigger)
        DispatchQueue.main.async { [weak self] in
            self?.executor.execute(action)
            self?.onGesture?(trigger, action)
            self?.onInputStatus?("Input: \(AppText.triggerName(trigger)) → \(AppText.actionName(action))")
        }
    }
}
