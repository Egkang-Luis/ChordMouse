import Cocoa

/// Replace this backend with a gesture session API for future continuous native-like gestures.
protocol GestureExecutor { func execute(_ direction: Direction) }

final class KeyboardGestureExecutor: GestureExecutor {
    private let resolver = SystemShortcutResolver()
    private var shortcuts: [Direction: SystemShortcut] = [:]
    private var horizontalSwapped = true

    @discardableResult
    func reloadSystemShortcuts() -> [Direction] {
        shortcuts = resolver.load()
        return Direction.allCases.filter { shortcuts[$0] != nil }
    }

    func setHorizontalSwapped(_ value: Bool) {
        horizontalSwapped = value
    }

    func execute(_ direction: Direction) {
        let resolvedDirection: Direction
        if horizontalSwapped {
            resolvedDirection = direction == .left ? .right : (direction == .right ? .left : direction)
        } else {
            resolvedDirection = direction
        }
        guard let shortcut = shortcuts[resolvedDirection] else { return }
        let source = CGEventSource(stateID: .privateState)
        guard let down = CGEvent(keyboardEventSource: source, virtualKey: shortcut.keyCode, keyDown: true),
              let up = CGEvent(keyboardEventSource: source, virtualKey: shortcut.keyCode, keyDown: false) else { return }
        down.flags = shortcut.flags
        up.flags = shortcut.flags
        down.post(tap: .cgSessionEventTap)
        up.post(tap: .cgSessionEventTap)
    }
}
