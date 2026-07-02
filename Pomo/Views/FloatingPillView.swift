//
//  FloatingPillView.swift
//  Pomo
//
//  The floating pill widget: phase label + countdown on the left,
//  session dots and circular controls on the right, in a dark capsule
//  tinted per phase. Mirrors the pomoshin reference design.
//

import SwiftUI

/// Layout constants for the pill.
private enum PillMetrics {
    static let height: CGFloat = 56
    static let horizontalPadding: CGFloat = 14
    static let itemSpacing: CGFloat = 12
    static let buttonSize: CGFloat = 30
    static let buttonSpacing: CGFloat = 6
    static let dotSize: CGFloat = 6
    static let dotSpacing: CGFloat = 5
    static let labelFontSize: CGFloat = 11
    static let labelTracking: CGFloat = 0.88 // 0.08em at 11pt
    static let timeFontSize: CGFloat = 22
    static let borderWidth: CGFloat = 1
}

/// Color constants for the pill (from the pomoshin reference).
private enum PillStyle {
    static let text = Color(red: 242 / 255, green: 243 / 255, blue: 247 / 255)
    static let accent = Color(red: 255 / 255, green: 107 / 255, blue: 94 / 255)
    static let border = Color.white.opacity(0.06)
    static let buttonFill = Color.white.opacity(0.10)
    static let buttonHoverFill = Color.white.opacity(0.22)
    static let quitHoverFill = Color(red: 240 / 255, green: 80 / 255, blue: 80 / 255).opacity(0.8)
    static let labelOpacity = 0.65
    static let emptyDot = Color.white.opacity(0.25)

    static func fill(for phase: Phase) -> Color {
        switch phase {
        case .focus: return Color(red: 38 / 255, green: 30 / 255, blue: 34 / 255).opacity(0.92)
        case .shortBreak: return Color(red: 24 / 255, green: 38 / 255, blue: 34 / 255).opacity(0.92)
        case .longBreak: return Color(red: 24 / 255, green: 30 / 255, blue: 44 / 255).opacity(0.92)
        }
    }
}

struct FloatingPillView: View {
    @EnvironmentObject private var engine: TimerEngine
    @EnvironmentObject private var settings: AppSettings

    var body: some View {
        HStack(spacing: PillMetrics.itemSpacing) {
            leftBlock
            dots
            controls
        }
        .padding(.horizontal, PillMetrics.horizontalPadding)
        .frame(height: PillMetrics.height)
        .background(
            Capsule().fill(PillStyle.fill(for: engine.phase))
        )
        .overlay(
            Capsule().strokeBorder(PillStyle.border, lineWidth: PillMetrics.borderWidth)
        )
        .fixedSize()
    }

    // MARK: - Sections

    private var leftBlock: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(engine.phase.title.uppercased())
                .font(.system(size: PillMetrics.labelFontSize, weight: .medium))
                .tracking(PillMetrics.labelTracking)
                .foregroundStyle(PillStyle.text.opacity(PillStyle.labelOpacity))
            Text(engine.displayString)
                .font(.system(size: PillMetrics.timeFontSize, weight: .semibold))
                .monospacedDigit()
                .foregroundStyle(PillStyle.text)
        }
    }

    private var dots: some View {
        let total = max(settings.sessionsPerLongBreak, 1)
        let filled = engine.completedFocusSessions % total
        return HStack(spacing: PillMetrics.dotSpacing) {
            ForEach(0..<total, id: \.self) { index in
                Circle()
                    .fill(index < filled ? PillStyle.accent : PillStyle.emptyDot)
                    .frame(width: PillMetrics.dotSize, height: PillMetrics.dotSize)
            }
        }
    }

    private var controls: some View {
        HStack(spacing: PillMetrics.buttonSpacing) {
            PillCircleButton(systemName: engine.isRunning ? "pause.fill" : "play.fill",
                             action: engine.toggle)
            PillCircleButton(systemName: "arrow.counterclockwise",
                             action: engine.reset)
            overflowMenu
            PillCircleButton(systemName: "xmark", isQuit: true) {
                NSApplication.shared.terminate(nil)
            }
        }
    }

    private var overflowMenu: some View {
        Menu {
            Button("Skip current period", action: engine.skip)
            Toggle("Auto-start next period", isOn: $settings.autoStartNextPhase)
            Divider()
            Button("Hide Floating Timer") { settings.showFloatingTimer = false }
        } label: {
            Image(systemName: "ellipsis")
                .foregroundStyle(PillStyle.text)
                .frame(width: PillMetrics.buttonSize, height: PillMetrics.buttonSize)
                .background(Circle().fill(PillStyle.buttonFill))
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .fixedSize()
    }
}

/// A 30pt circular control button that brightens on hover.
private struct PillCircleButton: View {
    let systemName: String
    var isQuit = false
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: PillMetrics.labelFontSize, weight: .semibold))
                .foregroundStyle(PillStyle.text)
                .frame(width: PillMetrics.buttonSize, height: PillMetrics.buttonSize)
                .background(Circle().fill(fillColor))
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }

    private var fillColor: Color {
        guard isHovered else { return PillStyle.buttonFill }
        return isQuit ? PillStyle.quitHoverFill : PillStyle.buttonHoverFill
    }
}
