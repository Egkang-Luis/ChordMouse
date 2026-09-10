import Cocoa
import ServiceManagement

@main
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var status: NSStatusItem!
    private let settings = GestureSettings()
    private let executor = KeyboardGestureExecutor()
    private lazy var engine = MouseEngine(executor: executor, settings: settings)
    private var stateItem: NSMenuItem!
    private var toggleItem: NSMenuItem!
    private var inputItem: NSMenuItem!
    private var launchAtLoginItem: NSMenuItem!
    private var settingsWindow: SettingsWindowController?

    static func main() {
        let app = NSApplication.shared; let delegate = AppDelegate(); app.delegate = delegate
        app.setActivationPolicy(.accessory); withExtendedLifetime(delegate) { app.run() }
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        status = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        status.button?.title = "⇄"; status.button?.toolTip = AppText.tooltip
        let menu = NSMenu()
        stateItem = item(AppText.starting, nil, menu)
        toggleItem = item(AppText.pause, #selector(toggle), menu)
        inputItem = item(AppText.inputWaiting, nil, menu)
        menu.addItem(.separator())
        _ = item(AppText.openGestureSettings, #selector(openGestureSettings), menu)
        launchAtLoginItem = item(AppText.launchAtLogin, #selector(toggleLaunchAtLogin(_:)), menu)
        menu.addItem(.separator())
        _ = item(AppText.extendedHelp, #selector(showHelp), menu)
        _ = item(AppText.accessibilitySettings, #selector(openAccessibility), menu)
        _ = item(AppText.reloadShortcuts, #selector(reloadSystemShortcuts), menu)
        _ = item(AppText.retry, #selector(retry), menu)
        _ = item(AppText.quit, #selector(quit), menu)
        status.menu = menu
        engine.onGesture = { [weak self] trigger, action in self?.inputItem.title = "\(AppText.triggerName(trigger)) → \(AppText.actionName(action))" }
        engine.onInputStatus = { [weak self] text in self?.inputItem.title = text }
        engine.onFailure = { [weak self] in self?.refresh() }
        reloadSystemShortcuts(); retry()
        refreshLaunchAtLoginItem()
        if !UserDefaults.standard.bool(forKey: "shownWelcome") {
            UserDefaults.standard.set(true, forKey: "shownWelcome")
            showHelp()
        }
    }

    private func item(_ title: String, _ action: Selector?, _ menu: NSMenu) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
        item.target = self; menu.addItem(item); return item
    }
    @objc private func openGestureSettings() {
        if settingsWindow == nil {
            settingsWindow = SettingsWindowController(settings: settings) { [weak self] trigger, action in
                self?.inputItem.title = "\(AppText.triggerName(trigger)) → \(AppText.actionName(action))"
            }
        }
        settingsWindow?.show()
    }
    private func refreshLaunchAtLoginItem() {
        switch SMAppService.mainApp.status {
        case .enabled:
            launchAtLoginItem.title = AppText.launchAtLogin; launchAtLoginItem.state = .on
        case .requiresApproval:
            launchAtLoginItem.title = AppText.launchNeedsApproval; launchAtLoginItem.state = .mixed
        default:
            launchAtLoginItem.title = AppText.launchAtLogin; launchAtLoginItem.state = .off
        }
    }
    @objc private func toggleLaunchAtLogin(_ sender: NSMenuItem) {
        do {
            switch SMAppService.mainApp.status {
            case .enabled:
                try SMAppService.mainApp.unregister(); inputItem.title = AppText.launchDisabled
            case .requiresApproval:
                inputItem.title = AppText.launchApprovalNeeded
                SMAppService.openSystemSettingsLoginItems()
            default:
                try SMAppService.mainApp.register(); inputItem.title = AppText.launchEnabled
            }
        } catch {
            inputItem.title = AppText.launchFailed(error.localizedDescription)
        }
        refreshLaunchAtLoginItem()
    }
    private func refresh() {
        stateItem.title = engine.running ? (engine.enabled ? AppText.active : AppText.paused) : AppText.needsPermission
        toggleItem.title = engine.enabled ? AppText.pause : AppText.resume
    }
    @objc private func retry() { _ = engine.restart(); refresh() }
    @objc private func toggle() { engine.setEnabled(!engine.enabled); refresh() }
    @objc private func reloadSystemShortcuts() {
        let available = executor.reloadSystemShortcuts()
        inputItem.title = available.count == 4 ? AppText.shortcutsSynced : AppText.shortcutsMissing(available.map(AppText.directionName).joined(separator: ", "))
    }
    @objc private func openAccessibility() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
    }
    @objc private func showHelp() {
        NSApp.activate(ignoringOtherApps: true)
        let alert = NSAlert(); alert.messageText = AppText.extendedHelp
        alert.informativeText = AppText.choose("두 버튼 드래그는 기존의 네 방향 데스크탑/Mission Control 제스처입니다.\n\n좌 버튼 유지 + 우 클릭: 실행 취소\n좌 버튼 유지 + 우 더블 클릭: 다시 실행\n우 버튼 유지 + 좌 클릭: 이전 탭\n우 버튼 유지 + 좌 더블 클릭: 다음 탭\n휠 버튼 유지 + 위/아래 스크롤: 볼륨 조절\n\n메뉴의 ‘제스처 설정 열기…’에서 모든 입력을 볼륨, 확대/축소, 밝기, 탭, 데스크탑, 음악, 실행 취소/다시 실행, Mission Control, App Exposé 중 하나로 바꿀 수 있습니다.", "Both-button drag keeps the original four-direction desktop and Mission Control controls.\n\nHold left + click right: Undo\nHold left + double-click right: Redo\nHold right + click left: Previous Tab\nHold right + double-click left: Next Tab\nHold middle + scroll up/down: Volume\n\nUse ‘Open Gesture Settings…’ to assign Volume, Zoom, Brightness, Tabs, Desktop, Tracks, Undo/Redo, Mission Control, or App Exposé to every input.")
        alert.addButton(withTitle: AppText.ok); alert.runModal()
    }
    @objc private func quit() { NSApp.terminate(nil) }
    func applicationWillTerminate(_ notification: Notification) { engine.stop() }
}
