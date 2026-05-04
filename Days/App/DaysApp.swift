import AppKit
import Combine
import SwiftUI

@main
final class DaysApp {
    private static var appDelegate: AppDelegate?

    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        appDelegate = delegate
        app.delegate = delegate
        app.run()
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let model = DaysModel()
    private var statusBarController: StatusBarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        statusBarController = StatusBarController(model: model)
    }
}

@MainActor
final class StatusBarController: NSObject {
    private let model: DaysModel
    private let statusItem: NSStatusItem
    private let panelContentSize = NSSize(width: 456, height: 448)
    private let panelArrowHeight: CGFloat = 14
    private var panel: CalendarPanelWindow?
    private var localEventMonitor: Any?
    private var globalEventMonitor: Any?
    private var panelReleaseTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    private var timer: Timer?

    init(model: DaysModel) {
        self.model = model
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        super.init()

        if let button = statusItem.button {
            button.target = self
            button.action = #selector(togglePopover(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }

        model.objectWillChange
            .sink { [weak self] _ in
                DispatchQueue.main.async {
                    self?.updateStatusItem()
                }
            }
            .store(in: &cancellables)

        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateStatusItem()
            }
        }

        updateStatusItem()
    }

    @objc private func togglePopover(_ sender: NSStatusBarButton) {
        if NSApp.currentEvent?.type == .rightMouseUp {
            showContextMenu(sender)
            return
        }

        if panel?.isVisible == true {
            closePanel()
        } else {
            showPanel(from: sender)
        }
    }

    private func showContextMenu(_ sender: NSStatusBarButton) {
        closePanel()

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "打开日历", action: #selector(openCalendar), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "设置", action: #selector(openSettings), keyEquivalent: ","))
        menu.addItem(NSMenuItem(title: "关于 Days", action: #selector(openAbout), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "退出 Days", action: #selector(quit), keyEquivalent: "q"))

        for item in menu.items {
            item.target = self
        }

        statusItem.menu = menu
        sender.performClick(nil)
        statusItem.menu = nil
    }

    @objc private func openCalendar() {
        guard let button = statusItem.button else {
            return
        }

        if panel?.isVisible != true {
            showPanel(from: button)
        }
    }

    @objc private func openSettings() {
        SettingsWindowPresenter.shared.show(model: model)
    }

    @objc private func openAbout() {
        AboutWindowPresenter.shared.show()
    }

    @objc private func quit() {
        releasePanel()
        NSApp.terminate(nil)
    }

    private func showPanel(from button: NSStatusBarButton) {
        cancelScheduledPanelRelease()
        let panel = preparePanel()
        position(panel, relativeTo: button)
        panel.orderFrontRegardless()
        panel.makeKey()
        NSApp.activate(ignoringOtherApps: true)
        installPanelEventMonitors()
    }

    private func position(_ panel: NSPanel, relativeTo button: NSStatusBarButton) {
        button.window?.layoutIfNeeded()
        guard let buttonWindow = button.window else {
            return
        }

        let buttonFrameInWindow = button.convert(button.bounds, to: nil)
        let buttonFrameOnScreen = buttonWindow.convertToScreen(buttonFrameInWindow)
        let screen = buttonWindow.screen ?? NSScreen.screens.first {
            NSMouseInRect(buttonFrameOnScreen.origin, $0.frame, false)
        }
        let visibleFrame = screen?.visibleFrame ?? NSScreen.main?.visibleFrame ?? buttonFrameOnScreen
        let windowFrame = panel.frame
        let margin: CGFloat = 8

        let proposedX = buttonFrameOnScreen.midX - windowFrame.width / 2
        let x = min(
            max(proposedX, visibleFrame.minX + margin),
            visibleFrame.maxX - windowFrame.width - margin
        )

        let proposedY = buttonFrameOnScreen.minY - windowFrame.height - 4
        let y = min(
            max(proposedY, visibleFrame.minY + margin),
            visibleFrame.maxY - windowFrame.height - margin
        )

        panel.setFrameOrigin(NSPoint(x: x, y: y))
    }

    private func preparePanel() -> CalendarPanelWindow {
        if let panel {
            return panel
        }

        let panelSize = NSSize(
            width: panelContentSize.width,
            height: panelContentSize.height + panelArrowHeight
        )
        let panel = CalendarPanelWindow(
            contentRect: NSRect(origin: .zero, size: panelSize),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        panel.level = .statusBar
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isReleasedWhenClosed = false

        let content = CalendarPanelContainerView(contentSize: panelContentSize, arrowHeight: panelArrowHeight)
            .environmentObject(model)
        let hostingController = NSHostingController(rootView: content)
        hostingController.view.frame = NSRect(origin: .zero, size: panelSize)
        hostingController.view.setFrameSize(panelSize)
        hostingController.view.wantsLayer = true
        hostingController.view.layer?.backgroundColor = NSColor.clear.cgColor
        hostingController.view.layoutSubtreeIfNeeded()
        panel.contentViewController = hostingController

        self.panel = panel
        return panel
    }

    private func closePanel() {
        removePanelEventMonitors()
        if panel?.isVisible == true {
            model.goToToday()
        }
        panel?.orderOut(nil)
        schedulePanelRelease()
    }

    private func installPanelEventMonitors() {
        removePanelEventMonitors()

        localEventMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            if self?.eventIsInStatusButton(event) == true {
                return event
            }

            Task { @MainActor in
                guard let self, let panel = self.panel, panel.isVisible, event.window !== panel else {
                    return
                }

                self.closePanel()
            }

            return event
        }

        globalEventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            Task { @MainActor in
                self?.closePanel()
            }
        }
    }

    private func eventIsInStatusButton(_ event: NSEvent) -> Bool {
        guard let button = statusItem.button, event.window === button.window else {
            return false
        }

        let point = button.convert(event.locationInWindow, from: nil)
        return button.bounds.contains(point)
    }

    private func removePanelEventMonitors() {
        if let localEventMonitor {
            NSEvent.removeMonitor(localEventMonitor)
            self.localEventMonitor = nil
        }

        if let globalEventMonitor {
            NSEvent.removeMonitor(globalEventMonitor)
            self.globalEventMonitor = nil
        }
    }

    private func schedulePanelRelease() {
        cancelScheduledPanelRelease()

        let delay = model.settings.panelReleaseDelay.interval
        guard delay > 0 else {
            releasePanelIfHidden()
            return
        }

        let timer = Timer(timeInterval: delay, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.releasePanelIfHidden()
            }
        }
        timer.tolerance = min(delay * 0.1, 2)
        RunLoop.main.add(timer, forMode: .common)
        panelReleaseTimer = timer
    }

    private func cancelScheduledPanelRelease() {
        panelReleaseTimer?.invalidate()
        panelReleaseTimer = nil
    }

    private func releasePanelIfHidden() {
        guard panel?.isVisible != true else {
            return
        }

        releasePanel()
    }

    private func releasePanel() {
        cancelScheduledPanelRelease()
        removePanelEventMonitors()
        guard let panel = panel else {
            return
        }

        panel.orderOut(nil)
        panel.contentViewController = nil
        panel.contentView = nil
        panel.close()
        self.panel = nil
    }

    private func updateStatusItem() {
        guard let button = statusItem.button else {
            return
        }

        button.title = model.menuBarTitle
        button.font = NSFont.menuBarFont(ofSize: 0)

        if model.settings.showsIcon {
            button.image = NSImage(systemSymbolName: "calendar", accessibilityDescription: "Days")
            button.imagePosition = .imageLeading
        } else {
            button.image = nil
        }
    }
}

@MainActor
final class AboutWindowPresenter: NSObject, NSWindowDelegate {
    static let shared = AboutWindowPresenter()

    private let repositoryURL = URL(string: "https://github.com/aderx/Days")!
    private var window: NSWindow?

    func show() {
        if let window, window.isVisible {
            NSApp.activate(ignoringOtherApps: true)
            window.level = .floating
            window.orderFrontRegardless()
            window.makeKeyAndOrderFront(nil)
            return
        } else if window != nil {
            releaseWindow()
        }

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 360, height: 300),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "关于 Days"
        window.contentView = makeContentView()
        window.center()
        window.level = .floating
        window.delegate = self
        window.isReleasedWhenClosed = false
        self.window = window

        NSApp.activate(ignoringOtherApps: true)
        window.orderFrontRegardless()
        window.makeKeyAndOrderFront(nil)
    }

    nonisolated func windowWillClose(_ notification: Notification) {
        Task { @MainActor in
            guard notification.object as AnyObject === self.window else {
                return
            }

            self.releaseWindow()
        }
    }

    private func releaseWindow() {
        guard let window else {
            return
        }

        window.delegate = nil
        window.contentView = nil
        self.window = nil
    }

    private func makeContentView() -> NSView {
        let root = NSView()
        root.wantsLayer = true
        root.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor

        let stack = NSStackView()
        stack.orientation = .vertical
        stack.alignment = .centerX
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false

        let iconView = NSImageView()
        iconView.image = appIcon
        iconView.imageScaling = .scaleProportionallyUpOrDown
        iconView.translatesAutoresizingMaskIntoConstraints = false

        let title = NSTextField(labelWithString: "Days")
        title.font = .systemFont(ofSize: 22, weight: .semibold)
        title.textColor = .labelColor

        let version = NSTextField(labelWithString: "V\(displayVersion)")
        version.font = .monospacedDigitSystemFont(ofSize: 13, weight: .medium)
        version.textColor = .secondaryLabelColor

        let description = NSTextField(labelWithString: "Days 是一个开源的 macOS 状态栏日历程序。")
        description.font = .systemFont(ofSize: 13)
        description.textColor = .secondaryLabelColor
        description.alignment = .center
        description.maximumNumberOfLines = 2

        let repoButton = NSButton(title: "查看开源地址", target: self, action: #selector(openRepository))
        repoButton.bezelStyle = .rounded

        let repoText = NSTextField(labelWithString: repositoryURL.absoluteString)
        repoText.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
        repoText.textColor = .tertiaryLabelColor
        repoText.alignment = .center
        repoText.lineBreakMode = .byTruncatingMiddle

        stack.addArrangedSubview(iconView)
        stack.addArrangedSubview(title)
        stack.addArrangedSubview(version)
        stack.addArrangedSubview(description)
        stack.addArrangedSubview(repoButton)
        stack.addArrangedSubview(repoText)
        root.addSubview(stack)

        NSLayoutConstraint.activate([
            iconView.widthAnchor.constraint(equalToConstant: 76),
            iconView.heightAnchor.constraint(equalToConstant: 76),
            stack.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: 28),
            stack.trailingAnchor.constraint(equalTo: root.trailingAnchor, constant: -28),
            stack.centerYAnchor.constraint(equalTo: root.centerYAnchor)
        ])

        return root
    }

    @objc private func openRepository() {
        NSWorkspace.shared.open(repositoryURL)
    }

    private var displayVersion: String {
        let raw = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0"
        let parts = raw.split(separator: ".")
        if parts.count == 2 {
            return "\(raw).0"
        }
        if parts.count == 1 {
            return "\(raw).0.0"
        }
        return raw
    }

    private var appIcon: NSImage? {
        if let image = NSImage(named: "AppIcon") {
            return image
        }

        guard let url = Bundle.main.url(forResource: "DaysIcon1024", withExtension: "png") else {
            return NSApp.applicationIconImage
        }
        return NSImage(contentsOf: url) ?? NSApp.applicationIconImage
    }
}

private final class CalendarPanelWindow: NSPanel {
    override var canBecomeKey: Bool {
        true
    }

    override var canBecomeMain: Bool {
        false
    }
}

private struct CalendarPanelContainerView: View {
    let contentSize: NSSize
    let arrowHeight: CGFloat

    var body: some View {
        ZStack(alignment: .top) {
            PanelBubbleShape(arrowHeight: arrowHeight, cornerRadius: 24)
                .fill(.ultraThinMaterial)
                .overlay {
                    PanelBubbleShape(arrowHeight: arrowHeight, cornerRadius: 24)
                        .fill(Color.white.opacity(0.22))
                }
                .overlay {
                    PanelBubbleShape(arrowHeight: arrowHeight, cornerRadius: 24)
                        .stroke(Color.black.opacity(0.15), lineWidth: 0.8)
                }

            CalendarPanelView()
                .frame(width: contentSize.width, height: contentSize.height, alignment: .topLeading)
                .padding(.top, arrowHeight)
        }
        .frame(width: contentSize.width, height: contentSize.height + arrowHeight)
        .environment(\.colorScheme, .light)
    }
}

private struct PanelBubbleShape: Shape {
    let arrowHeight: CGFloat
    let cornerRadius: CGFloat

    func path(in rect: CGRect) -> Path {
        let arrowHalfWidth: CGFloat = 18
        let arrowPeakX = rect.midX
        let bodyTop = rect.minY + arrowHeight
        let radius = min(cornerRadius, rect.width / 2, (rect.height - arrowHeight) / 2)

        var path = Path()

        path.move(to: CGPoint(x: arrowPeakX, y: rect.minY))
        path.addCurve(
            to: CGPoint(x: arrowPeakX + arrowHalfWidth, y: bodyTop),
            control1: CGPoint(x: arrowPeakX + 8, y: rect.minY),
            control2: CGPoint(x: arrowPeakX + 10, y: bodyTop)
        )
        path.addLine(to: CGPoint(x: rect.maxX - radius, y: bodyTop))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: bodyTop + radius),
            control: CGPoint(x: rect.maxX, y: bodyTop)
        )
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - radius))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX - radius, y: rect.maxY),
            control: CGPoint(x: rect.maxX, y: rect.maxY)
        )
        path.addLine(to: CGPoint(x: rect.minX + radius, y: rect.maxY))
        path.addQuadCurve(
            to: CGPoint(x: rect.minX, y: rect.maxY - radius),
            control: CGPoint(x: rect.minX, y: rect.maxY)
        )
        path.addLine(to: CGPoint(x: rect.minX, y: bodyTop + radius))
        path.addQuadCurve(
            to: CGPoint(x: rect.minX + radius, y: bodyTop),
            control: CGPoint(x: rect.minX, y: bodyTop)
        )
        path.addLine(to: CGPoint(x: arrowPeakX - arrowHalfWidth, y: bodyTop))
        path.addCurve(
            to: CGPoint(x: arrowPeakX, y: rect.minY),
            control1: CGPoint(x: arrowPeakX - 10, y: bodyTop),
            control2: CGPoint(x: arrowPeakX - 8, y: rect.minY)
        )
        path.closeSubpath()
        return path
    }
}
