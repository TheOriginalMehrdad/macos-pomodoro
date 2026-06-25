//
//  MenuBarLabel.swift
//  Pomo
//
//  The menu bar item: a live countdown (expanded) or a timer icon (compact).
//

import SwiftUI

struct MenuBarLabel: View {
    @ObservedObject var engine: TimerEngine
    @ObservedObject var settings: AppSettings

    private let fontSize: CGFloat = 12
    private let horizontalPadding: CGFloat = 5
    private let verticalPadding: CGFloat = 1.5
    private let cornerRadius: CGFloat = 4
    private let strokeWidth: CGFloat = 1

    var body: some View {
        switch settings.menuBarMode {
        case .expanded:
            // The menu bar renders a plain Text label as a native title and
            // ignores SwiftUI overlays, so the outline must be rasterized into
            // a template image that the system tints to match the menu bar.
            if let image = renderedTimer(engine.displayString) {
                Image(nsImage: image)
            } else {
                Text(engine.displayString)
                    .monospacedDigit()
            }
        case .compact:
            Image(systemName: engine.isRunning ? "timer" : "timer.circle")
        }
    }

    private func renderedTimer(_ text: String) -> NSImage? {
        let content = Text(text)
            .font(.system(size: fontSize).monospacedDigit())
            .foregroundStyle(.black)
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
            .overlay(
                // strokeBorder draws the line fully inside the bounds so it is
                // not clipped at the image edge, keeping the outline crisp.
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(.black, lineWidth: strokeWidth)
            )

        let renderer = ImageRenderer(content: content)
        // Render at a high, fixed scale so the menu bar always has enough
        // resolution to display a sharp outline on any display.
        renderer.scale = max(3, NSScreen.main?.backingScaleFactor ?? 3)

        guard let image = renderer.nsImage else { return nil }
        image.isTemplate = true // let macOS tint it for light/dark menu bars
        return image
    }
}
