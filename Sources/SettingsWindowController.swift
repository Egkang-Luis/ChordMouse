import Cocoa

/// A small frame-based settings window. It deliberately avoids nested Auto Layout
/// views because this window can be opened while the menu-bar event loop is active.
final class SettingsWindowController: NSWindowController {
    private let settings: GestureSettings
    private let onChange: (GestureTrigger, GestureAction) -> Void

    init(settings: GestureSettings, onChange: @escaping (GestureTrigger, GestureAction) -> Void) {
        self.settings = settings
        self.onChange = onChange
        // Keep the last menu comfortably above the explanatory note. The
        // settings list is intentionally frame based, so its height is tied
        // to the number of visible gesture rows.
        let contentHeight = max(CGFloat(600), CGFloat(GestureTrigger.allCases.count) * 34 + 192)
        let frame = NSRect(x: 0, y: 0, width: 620, height: contentHeight)
        let window = NSWindow(contentRect: frame, styleMask: [.titled, .closable, .miniaturizable], backing: .buffered, defer: false)
        window.title = AppText.choose("ChordMouse 제스처 설정", "ChordMouse Gesture Settings")
        window.minSize = NSSize(width: 620, height: contentHeight)
        window.isReleasedWhenClosed = false
        super.init(window: window)
        buildContents(in: NSView(frame: frame))
        window.center()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    func show() {
        window?.center()
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func buildContents(in root: NSView) {
        root.autoresizingMask = [.width, .height]
        window?.contentView = root

        let title = NSTextField(labelWithString: AppText.choose("제스처별 동작", "Actions for each gesture"))
        title.font = .systemFont(ofSize: 18, weight: .semibold)
        title.frame = NSRect(x: 24, y: root.bounds.height - 42, width: 560, height: 25)
        root.addSubview(title)

        let detail = NSTextField(labelWithString: AppText.choose("오른쪽 메뉴에서 동작을 고르면 즉시 저장되고 다음 제스처부터 적용됩니다.", "Choose an action from the menu. It saves immediately and applies to the next gesture."))
        detail.textColor = .secondaryLabelColor
        detail.frame = NSRect(x: 24, y: root.bounds.height - 68, width: 570, height: 20)
        root.addSubview(detail)

        var y = root.bounds.height - 110
        for trigger in GestureTrigger.allCases {
            let label = NSTextField(labelWithString: AppText.triggerName(trigger))
            label.frame = NSRect(x: 24, y: y + 4, width: 315, height: 22)
            label.lineBreakMode = .byTruncatingTail
            root.addSubview(label)

            let picker = NSPopUpButton(frame: NSRect(x: 350, y: y, width: 245, height: 28), pullsDown: false)
            for action in GestureAction.allCases { picker.addItem(withTitle: AppText.actionName(action)) }
            picker.selectItem(at: GestureAction.allCases.firstIndex(of: settings.action(for: trigger)) ?? 0)
            picker.target = self
            picker.action = #selector(changeAction(_:))
            picker.identifier = NSUserInterfaceItemIdentifier(trigger.rawValue)
            root.addSubview(picker)
            y -= 34
        }

        let line = NSBox(frame: NSRect(x: 24, y: 76, width: 571, height: 1))
        line.boxType = .separator
        root.addSubview(line)
        let note = NSTextField(wrappingLabelWithString: AppText.choose("Mission Control, App Exposé, 데스크탑 전환은 macOS의 현재 키보드 단축키를 사용합니다.", "Mission Control, App Exposé, and desktop switching use your current macOS keyboard shortcuts."))
        note.textColor = .secondaryLabelColor
        note.frame = NSRect(x: 24, y: 22, width: 570, height: 40)
        root.addSubview(note)
    }

    @objc private func changeAction(_ sender: NSPopUpButton) {
        guard let raw = sender.identifier?.rawValue,
              let trigger = GestureTrigger(rawValue: raw),
              sender.indexOfSelectedItem >= 0 else { return }
        let action = GestureAction.allCases[sender.indexOfSelectedItem]
        settings.set(action, for: trigger)
        onChange(trigger, action)
    }
}
