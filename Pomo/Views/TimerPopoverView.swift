//
//  TimerPopoverView.swift
//  Pomo
//
//  The dropdown popover: dark scrubber UI with presets, a start/pause control,
//  and a large countdown, mirroring the reference design.
//

import SwiftUI

struct TimerPopoverView: View {
    @EnvironmentObject private var engine: TimerEngine
    @EnvironmentObject private var settings: AppSettings

    private let popoverWidth: CGFloat = 340

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            ScrubberView(minutes: focusMinutesBinding,
                         highContrast: settings.increaseContrast)
            PresetChipsView(presets: settings.presets,
                            highContrast: settings.increaseContrast) { minutes in
                engine.setFocusMinutes(minutes)
            }
            Divider().overlay(.white.opacity(0.12))
            footer
        }
        .padding(20)
        .frame(width: popoverWidth)
        .background(backgroundColor)
    }

    // MARK: - Sections

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 6) {
                Text(engine.phase.title)
                    .font(.headline)
                    .foregroundStyle(engine.phase.tint)
                sessionDots
            }
            Spacer()
            overflowMenu
        }
    }

    private var footer: some View {
        HStack(alignment: .bottom) {
            Button(action: engine.toggle) {
                Text(engine.isRunning ? "pause" : "start")
                    .font(.title3)
                    .foregroundStyle(.white)
            }
            .buttonStyle(.plain)
            Spacer()
            Text(engine.displayString)
                .font(.system(size: 64, weight: .light))
                .monospacedDigit()
                .foregroundStyle(.white)
        }
    }

    private var sessionDots: some View {
        let total = max(settings.sessionsPerLongBreak, 1)
        let filled = engine.completedFocusSessions % total
        return HStack(spacing: 5) {
            ForEach(0..<total, id: \.self) { index in
                Circle()
                    .fill(.white.opacity(index < filled ? 0.9 : 0.25))
                    .frame(width: 6, height: 6)
            }
        }
    }

    private var overflowMenu: some View {
        Menu {
            Button("Reset", action: engine.reset)
            Button("Skip", action: engine.skip)
            Divider()
            Toggle("Floating Timer", isOn: $settings.showFloatingTimer)
            Divider()
            SettingsLink { Text("Settings…") }
            Divider()
            Button("Quit Pomo") { NSApplication.shared.terminate(nil) }
        } label: {
            Image(systemName: "ellipsis")
                .foregroundStyle(.white.opacity(0.8))
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .fixedSize()
    }

    // MARK: - Helpers

    private var backgroundColor: Color {
        Color(white: settings.increaseContrast ? 0.10 : 0.18)
    }

    private var focusMinutesBinding: Binding<Int> {
        Binding(
            get: { settings.focusMinutes },
            set: { engine.setFocusMinutes($0) }
        )
    }
}
