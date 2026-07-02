//
//  FloatingPillController.swift
//  Pomo
//
//  Owns the floating pill panel and shows/hides it as the
//  `showFloatingTimer` setting changes.
//

import AppKit
import SwiftUI
import Combine

@MainActor
final class FloatingPillController: ObservableObject {
    private let settings: AppSettings
    private let engine: TimerEngine
    private var panel: FloatingPillPanel?
    private var cancellables = Set<AnyCancellable>()

    private static let frameAutosaveName = "FloatingPillPanel"
    private static let firstLaunchMargin: CGFloat = 24

    init(settings: AppSettings, engine: TimerEngine) {
        self.settings = settings
        self.engine = engine
        // No dropFirst: @Published replays the current value, so the panel
        // is restored on launch when the setting is already on.
        // receive(on:) is required: this controller is created in PomoApp.init,
        // before AppKit is running, and creating an NSPanel that early kills
        // the app. The main queue only drains once the run loop starts.
        settings.$showFloatingTimer
            .receive(on: DispatchQueue.main)
            .sink { [weak self] show in
                show ? self?.showPanel() : self?.hidePanel()
            }
            .store(in: &cancellables)
    }

    private func showPanel() {
        let panel = self.panel ?? makePanel()
        self.panel = panel
        panel.orderFrontRegardless()
    }

    private func hidePanel() {
        panel?.close()
    }

    private func makePanel() -> FloatingPillPanel {
        let panel = FloatingPillPanel()
        let root = FloatingPillView()
            .environmentObject(engine)
            .environmentObject(settings)
        let hosting = NSHostingView(rootView: root)
        hosting.sizingOptions = [.intrinsicContentSize]
        panel.contentView = hosting
        panel.setContentSize(hosting.fittingSize)
        positionPanel(panel)
        return panel
    }

    /// Restore the saved position, or default to the screen's top-right corner.
    private func positionPanel(_ panel: FloatingPillPanel) {
        panel.setFrameAutosaveName(FloatingPillController.frameAutosaveName)
        let hasSavedFrame = UserDefaults.standard
            .string(forKey: "NSWindow Frame \(FloatingPillController.frameAutosaveName)") != nil
        guard !hasSavedFrame, let screen = NSScreen.main else { return }
        let visible = screen.visibleFrame
        let margin = FloatingPillController.firstLaunchMargin
        let origin = NSPoint(
            x: visible.maxX - panel.frame.width - margin,
            y: visible.maxY - panel.frame.height - margin
        )
        panel.setFrameOrigin(origin)
    }
}
