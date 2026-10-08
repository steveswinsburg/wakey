import Cocoa
import IOKit.pwr_mgt
import ServiceManagement

/// Simple menu-bar utility that prevents the Mac from sleeping, in the
/// spirit of the classic "Caffeine" app. Click the lightbulb to toggle it
/// on/off. Right-click (or control-click) for options.
final class AppDelegate: NSObject, NSApplicationDelegate {

    private var statusItem: NSStatusItem!
    private var assertionID: IOPMAssertionID = 0
    private var displayAssertionID: IOPMAssertionID = 0
    private var sleepTimer: Timer?
    private var awakeUntil: Date?
    private var selectedDuration: TimeInterval?
    private var isAwake = false {
        didSet { updateIcon() }
    }

    // Native SF Symbols render crisply at menu bar size and automatically
    // adapt to light/dark mode and accessibility settings.
    private let bulbOffImage: NSImage? = {
        let config = NSImage.SymbolConfiguration(pointSize: 14, weight: .regular)
        let image = NSImage(systemSymbolName: "lightbulb", accessibilityDescription: "Wakey is off")
        return image?.withSymbolConfiguration(config)
    }()
    private let bulbOnImage: NSImage? = {
        let config = NSImage.SymbolConfiguration(pointSize: 14, weight: .regular)
        let image = NSImage(systemSymbolName: "lightbulb.fill", accessibilityDescription: "Wakey is on")
        return image?.withSymbolConfiguration(config)
    }()

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem.button {
            button.image = bulbOffImage
            button.image?.isTemplate = true
            button.target = self
            button.action = #selector(statusItemClicked(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        if isAwake {
            stopPreventingSleep()
        }
    }

    @objc private func statusItemClicked(_ sender: Any?) {
        let event = NSApp.currentEvent

        if event?.type == .rightMouseUp {
            showMenu()
        } else {
            // A plain click always toggles the simple "forever" mode.
            if isAwake {
                turnOffAwake()
            } else {
                startAwake(duration: nil)
            }
        }
    }

    /// Starts preventing sleep. `duration` of `nil` means "forever" (stays
    /// on until clicked again); otherwise it auto-turns-off after that
    /// many seconds.
    private func startAwake(duration: TimeInterval?) {
        sleepTimer?.invalidate()
        sleepTimer = nil
        selectedDuration = duration

        if !isAwake {
            isAwake = true
            startPreventingSleep()
        }

        if let duration = duration {
            awakeUntil = Date().addingTimeInterval(duration)
            sleepTimer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { [weak self] _ in
                self?.turnOffAwake()
            }
        } else {
            awakeUntil = nil
        }
    }

    private func turnOffAwake() {
        sleepTimer?.invalidate()
        sleepTimer = nil
        awakeUntil = nil
        selectedDuration = nil
        isAwake = false
        stopPreventingSleep()
    }

    private func updateIcon() {
        statusItem.button?.image = isAwake ? bulbOnImage : bulbOffImage
        statusItem.button?.image?.isTemplate = true
    }

    // MARK: - Power management

    private func startPreventingSleep() {
        let reason = "User enabled Wakey" as CFString
        let result = IOPMAssertionCreateWithName(
            kIOPMAssertionTypePreventUserIdleSystemSleep as CFString,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            reason,
            &assertionID
        )
        if result != kIOReturnSuccess {
            isAwake = false
        }

        // Also keep the display on, matching Caffeine's default behaviour.
        var newDisplayAssertionID: IOPMAssertionID = 0
        IOPMAssertionCreateWithName(
            kIOPMAssertionTypeNoDisplaySleep as CFString,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            reason,
            &newDisplayAssertionID
        )
        displayAssertionID = newDisplayAssertionID
    }

    private func stopPreventingSleep() {
        if assertionID != 0 {
            IOPMAssertionRelease(assertionID)
            assertionID = 0
        }
        if displayAssertionID != 0 {
            IOPMAssertionRelease(displayAssertionID)
            displayAssertionID = 0
        }
    }

    // MARK: - Menu

    private func showMenu() {
        let menu = NSMenu()

        let statusLabel = NSMenuItem(title: statusLabelTitle(), action: nil, keyEquivalent: "")
        statusLabel.isEnabled = false
        menu.addItem(statusLabel)
        menu.addItem(.separator())

        for option in durationOptions {
            let item = NSMenuItem(title: option.title, action: #selector(durationItemSelected(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = option.duration
            item.state = isCurrentDuration(option.duration) ? .on : .off
            menu.addItem(item)
        }

        menu.addItem(.separator())
        let loginItem = NSMenuItem(title: "Launch at Login", action: #selector(toggleLaunchAtLogin(_:)), keyEquivalent: "")
        loginItem.target = self
        loginItem.state = isLaunchAtLoginEnabled() ? .on : .off
        menu.addItem(loginItem)

        menu.addItem(.separator())
        let quitItem = NSMenuItem(title: "Quit Wakey", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        // Reset so a plain left click goes back to toggling instead of
        // always reopening this menu.
        statusItem.menu = nil
    }

    /// The selectable "keep awake for" durations, in the order they are
    /// shown in the menu. `duration` of `nil` means "Forever".
    private let durationOptions: [(title: String, duration: TimeInterval?)] = [
        ("1 Hour", 60 * 60),
        ("2 Hours", 2 * 60 * 60),
        ("4 Hours", 4 * 60 * 60),
        ("Forever", nil)
    ]

    private func isCurrentDuration(_ duration: TimeInterval?) -> Bool {
        isAwake && selectedDuration == duration
    }

    private func statusLabelTitle() -> String {
        guard isAwake else { return "Wakey is OFF" }
        guard let until = awakeUntil else { return "Wakey is ON (forever)" }
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return "Wakey is ON until \(formatter.string(from: until))"
    }

    @objc private func durationItemSelected(_ sender: NSMenuItem) {
        let duration = sender.representedObject as? TimeInterval
        startAwake(duration: duration)
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }

    // MARK: - Launch at login

    private func isLaunchAtLoginEnabled() -> Bool {
        if #available(macOS 13.0, *) {
            return SMAppService.mainApp.status == .enabled
        }
        return false
    }

    @objc private func toggleLaunchAtLogin(_ sender: NSMenuItem) {
        if #available(macOS 13.0, *) {
            do {
                if SMAppService.mainApp.status == .enabled {
                    try SMAppService.mainApp.unregister()
                } else {
                    try SMAppService.mainApp.register()
                }
            } catch {
                NSLog("Failed to toggle launch at login: \(error)")
            }
        }
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
