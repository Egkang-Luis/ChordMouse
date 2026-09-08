import Cocoa

struct SystemShortcut {
    let keyCode: CGKeyCode
    let flags: CGEventFlags
}

/// Reads the keyboard shortcuts that macOS itself uses for Mission Control.
/// macOS exposes no dedicated public Mission Control shortcut API. Its symbolic
/// hotkey preference is the same source System Settings writes, so this keeps
/// ChordMouse aligned with user-customized keyboard shortcuts without changing
/// any system setting.
final class SystemShortcutResolver {
    private let identifiers: [Direction: String] = [
        .up: "32",       // Mission Control
        .down: "33",     // Application Windows / App Exposé
        .left: "79",     // Move left a space
        .right: "81"     // Move right a space
    ]

    func load() -> [Direction: SystemShortcut] {
        guard let hotkeys = CFPreferencesCopyAppValue(
            "AppleSymbolicHotKeys" as CFString,
            "com.apple.symbolichotkeys" as CFString
        ) as? [String: Any] else { return [:] }

        return identifiers.reduce(into: [:]) { result, item in
            guard let entry = hotkeys[item.value] as? [String: Any],
                  (entry["enabled"] as? NSNumber)?.boolValue == true,
                  let value = entry["value"] as? [String: Any],
                  let parameters = value["parameters"] as? [NSNumber],
                  parameters.count >= 3 else { return }

            result[item.key] = SystemShortcut(
                keyCode: CGKeyCode(parameters[1].uint16Value),
                // This includes any Fn/numeric-pad bits stored by macOS, which
                // are needed for some custom Space-switching configurations.
                flags: CGEventFlags(rawValue: parameters[2].uint64Value)
            )
        }
    }
}
