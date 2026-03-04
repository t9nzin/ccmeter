import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private let aggregator = UsageAggregator()
    private var observation: Any?

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.image = MenuBarIcon.generateIcon(percentage: 0)
            button.imagePosition = .imageLeading
            button.title = "–"
            button.action = #selector(togglePopover)
            button.target = self
        }

        let popover = NSPopover()
        popover.contentSize = NSSize(width: 280, height: 200)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(
            rootView: PopoverView(aggregator: aggregator)
        )
        self.popover = popover

        aggregator.start()

        // Observe changes to update menu bar icon + text
        observation = withObservationTracking {
            _ = aggregator.menuBarText
        } onChange: { [weak self] in
            DispatchQueue.main.async {
                self?.updateMenuBar()
            }
        }
        updateMenuBar()
    }

    func applicationWillTerminate(_ notification: Notification) {
        aggregator.stop()
    }

    private func updateMenuBar() {
        statusItem?.button?.image = MenuBarIcon.generateIcon(percentage: aggregator.sessionUtilization)
        statusItem?.button?.title = aggregator.menuBarText

        // Re-register observation
        observation = withObservationTracking {
            _ = aggregator.menuBarText
        } onChange: { [weak self] in
            DispatchQueue.main.async {
                self?.updateMenuBar()
            }
        }
    }

    @objc private func togglePopover() {
        guard let button = statusItem.button else { return }

        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            // Ensure the popover's window becomes key so it can receive events
            popover.contentViewController?.view.window?.makeKey()
        }
    }
}
