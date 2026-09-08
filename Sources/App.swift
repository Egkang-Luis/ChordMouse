import Cocoa
import ServiceManagement

@main
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var status: NSStatusItem!
    private let keyboardExecutor = KeyboardGestureExecutor()
    private lazy var engine = MouseEngine(executor: keyboardExecutor)
    private var stateItem: NSMenuItem!
    private var toggleItem: NSMenuItem!
    private var lastItem: NSMenuItem!
    private var inputItem: NSMenuItem!
    private var launchAtLoginItem: NSMenuItem!
    private let horizontalSwapKey = "horizontalSwap"

    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.setActivationPolicy(.accessory)
        withExtendedLifetime(delegate) { app.run() }
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        status = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        status.button?.title = "⇄"
        status.button?.toolTip = AppText.tooltip
        let menu = NSMenu()
        stateItem = item(AppText.starting, nil, menu)
        toggleItem = item(AppText.pause, #selector(toggle), menu)
        lastItem = item(AppText.noGesture, nil, menu)
        inputItem = item(AppText.inputWaiting, nil, menu)
        menu.addItem(.separator())
        _ = item(AppText.swapHorizontal, #selector(toggleHorizontalSwap(_:)), menu)
        launchAtLoginItem = item(AppText.launchAtLogin, #selector(toggleLaunchAtLogin(_:)), menu)
        _ = item(AppText.help, #selector(showHelp), menu)
        _ = item(AppText.accessibilitySettings, #selector(openAccessibility), menu)
        _ = item(AppText.reloadShortcuts, #selector(reloadSystemShortcuts), menu)
        _ = item(AppText.retry, #selector(retry), menu)
        menu.addItem(.separator())
        _ = item(AppText.quit, #selector(quit), menu)
        status.menu = menu
        engine.onGesture = { [weak self] d in self?.lastItem.title = AppText.lastGesture(d) }
        engine.onInputStatus = { [weak self] status in self?.inputItem.title = status }
        engine.onFailure = { [weak self] in self?.refresh() }
        applySavedSettings()
        refreshLaunchAtLoginItem()
        reloadSystemShortcuts()
        retry()
        if !UserDefaults.standard.bool(forKey: "shownWelcome") {
            UserDefaults.standard.set(true, forKey: "shownWelcome")
            showHelp()
        }
    }

    private func item(_ title: String, _ action: Selector?, _ menu: NSMenu) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
        item.target = self; menu.addItem(item); return item
    }
    private func refresh() {
        stateItem.title = engine.running ? (engine.enabled ? AppText.active : AppText.paused) : AppText.needsPermission
        toggleItem.title = engine.enabled ? AppText.pause : AppText.resume
    }
    @objc private func retry() { _ = engine.restart(); refresh() }
    private var horizontalSwapped: Bool {
        UserDefaults.standard.object(forKey: horizontalSwapKey) as? Bool ?? true
    }
    private func applySavedSettings() {
        keyboardExecutor.setHorizontalSwapped(horizontalSwapped)
        if let menuItem = status.menu?.items.first(where: { $0.action == #selector(toggleHorizontalSwap(_:)) }) {
            menuItem.state = horizontalSwapped ? .on : .off
        }
    }
    @objc private func toggleHorizontalSwap(_ sender: NSMenuItem) {
        UserDefaults.standard.set(!horizontalSwapped, forKey: horizontalSwapKey)
        applySavedSettings()
        inputItem.title = horizontalSwapped ? AppText.swapped : AppText.normalDirection
    }
    private func refreshLaunchAtLoginItem() {
        switch SMAppService.mainApp.status {
        case .enabled:
            launchAtLoginItem.title = AppText.launchAtLogin
            launchAtLoginItem.state = .on
        case .requiresApproval:
            launchAtLoginItem.title = AppText.launchNeedsApproval
            launchAtLoginItem.state = .mixed
        default:
            launchAtLoginItem.title = AppText.launchAtLogin
            launchAtLoginItem.state = .off
        }
    }
    @objc private func toggleLaunchAtLogin(_ sender: NSMenuItem) {
        do {
            switch SMAppService.mainApp.status {
            case .enabled:
                try SMAppService.mainApp.unregister()
                inputItem.title = AppText.launchDisabled
            case .requiresApproval:
                inputItem.title = AppText.launchApprovalNeeded
                SMAppService.openSystemSettingsLoginItems()
            default:
                try SMAppService.mainApp.register()
                inputItem.title = AppText.launchEnabled
            }
        } catch {
            inputItem.title = AppText.launchFailed(error.localizedDescription)
        }
        refreshLaunchAtLoginItem()
    }
    @objc private func reloadSystemShortcuts() {
        let available = keyboardExecutor.reloadSystemShortcuts()
        let missing = Direction.allCases.filter { !available.contains($0) }
        if missing.isEmpty {
            inputItem?.title = AppText.shortcutsSynced
        } else {
            let names = missing.map(\.rawValue).joined(separator: ", ")
            inputItem?.title = AppText.shortcutsMissing(names)
        }
    }
    @objc private func toggle() { engine.setEnabled(!engine.enabled); refresh() }
    @objc private func openAccessibility() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }
    @objc private func showHelp() {
        NSApp.activate(ignoringOtherApps: true)
        let alert = NSAlert()
        alert.messageText = AppText.helpTitle
        alert.informativeText = AppText.helpMessage
        alert.addButton(withTitle: AppText.ok)
        alert.addButton(withTitle: AppText.accessibilitySettings)
        if alert.runModal() == .alertSecondButtonReturn { openAccessibility() }
    }
    @objc private func quit() { NSApp.terminate(nil) }
    func applicationWillTerminate(_ notification: Notification) { engine.stop() }
}
