import Cocoa

enum GestureAction: String, CaseIterable {
    case volumeUp, volumeDown, zoomIn, zoomOut, brightnessUp, brightnessDown
    case nextTab, previousTab, nextSpace, previousSpace, nextTrack, previousTrack
    case back, forward, focusZoom, undo, redo, missionControl, appExpose
}

final class GestureSettings {
    private let prefix = "extendedAction."
    private let defaults: [GestureTrigger: GestureAction] = [
        .dragLeft: .nextSpace, .dragRight: .previousSpace, .dragUp: .missionControl, .dragDown: .appExpose,
        .leftHoldRightClick: .forward, .leftHoldRightDoubleClick: .nextTab,
        .rightHoldLeftClick: .back, .rightHoldLeftDoubleClick: .previousTab,
        .leftRightLeftRight: .focusZoom, .rightLeftRightLeft: .zoomOut,
        .middleScrollUp: .volumeDown, .middleScrollDown: .volumeUp
    ]
    func action(for trigger: GestureTrigger) -> GestureAction {
        guard let raw = UserDefaults.standard.string(forKey: prefix + trigger.rawValue), let action = GestureAction(rawValue: raw) else {
            // Newly introduced triggers may not have a stored preference yet.
            // Use a harmless fallback rather than terminating the settings window.
            return defaults[trigger] ?? .focusZoom
        }
        return action
    }
    func set(_ action: GestureAction, for trigger: GestureTrigger) { UserDefaults.standard.set(action.rawValue, forKey: prefix + trigger.rawValue) }
}

final class KeyboardGestureExecutor {
    private let resolver = SystemShortcutResolver()
    private var systemShortcuts: [Direction: SystemShortcut] = [:]
    @discardableResult func reloadSystemShortcuts() -> [Direction] { systemShortcuts = resolver.load(); return Direction.allCases.filter { systemShortcuts[$0] != nil } }
    func execute(_ action: GestureAction) {
        switch action {
        case .volumeUp: postMediaKey(0); case .volumeDown: postMediaKey(1)
        case .brightnessUp: postMediaKey(2); case .brightnessDown: postMediaKey(3)
        case .nextTrack: postMediaKey(17); case .previousTrack: postMediaKey(16)
        case .zoomIn: postKey(24, [.maskCommand]); case .zoomOut: postKey(27, [.maskCommand])
        case .nextTab: postKey(48, [.maskControl]); case .previousTab: postKey(48, [.maskControl, .maskShift])
        case .back: postKey(33, [.maskCommand])
        case .forward: postKey(30, [.maskCommand])
        // Uses the standard document zoom-in shortcut. Preview/PDF viewers,
        // Safari, and many other macOS apps support Command + plus directly.
        case .focusZoom: postKey(24, [.maskCommand])
        case .undo: postKey(6, [.maskCommand]); case .redo: postKey(6, [.maskCommand, .maskShift])
        case .previousSpace: postSystemShortcut(.left); case .nextSpace: postSystemShortcut(.right)
        case .missionControl: postSystemShortcut(.up); case .appExpose: postSystemShortcut(.down)
        }
    }
    private func postSystemShortcut(_ direction: Direction) { guard let shortcut = systemShortcuts[direction] else { return }; postKey(shortcut.keyCode, shortcut.flags) }
    private func postKey(_ keyCode: CGKeyCode, _ flags: CGEventFlags) {
        let source = CGEventSource(stateID: .privateState)
        guard let down = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: true), let up = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: false) else { return }
        down.flags = flags; up.flags = flags; down.post(tap: .cgSessionEventTap); up.post(tap: .cgSessionEventTap)
    }
    private func postMediaKey(_ keyType: Int32) {
        for state: Int32 in [0xA, 0xB] {
            let data1 = (keyType << 16) | (state << 8)
            NSEvent.otherEvent(with: .systemDefined, location: .zero, modifierFlags: [], timestamp: 0, windowNumber: 0, context: nil, subtype: 8, data1: Int(data1), data2: -1)?.cgEvent?.post(tap: .cghidEventTap)
        }
    }
}
