//
//  SettingsView.swift
//  Pomo
//
//  The preferences window (⌘,), mirroring the reference settings screen.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var engine: TimerEngine

    private let windowWidth: CGFloat = 360

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            presetsSection
            Divider()
            pomodoroSection
            Divider()
            alarmSection
            Divider()
            menuBarSection
            Divider()
            floatingTimerSection
            Divider()
            launchSection
        }
        .padding(20)
        .frame(width: windowWidth)
    }

    // MARK: - Sections

    private var presetsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("timer presets (min):").font(.headline)
            HStack(spacing: 12) {
                ForEach(0..<SettingsDefault.presetCount, id: \.self) { index in
                    presetStepper(index: index)
                }
            }
        }
    }

    private var pomodoroSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("pomodoro (min):").font(.headline)
            minuteStepper("focus", value: $settings.focusMinutes)
            minuteStepper("short break", value: $settings.shortBreakMinutes)
            minuteStepper("long break", value: $settings.longBreakMinutes)
            Stepper(value: $settings.sessionsPerLongBreak, in: 1...12) {
                Text("long break every \(settings.sessionsPerLongBreak) sessions")
            }
            Toggle("auto-start next phase", isOn: $settings.autoStartNextPhase)
        }
    }

    private var alarmSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("alarm volume:").font(.headline)
            HStack {
                Image(systemName: "speaker.fill")
                Slider(value: $settings.alarmVolume, in: 0...1)
                Image(systemName: "speaker.wave.3.fill")
            }
            Toggle("automatically mute after 5 seconds",
                   isOn: $settings.autoMuteAfterFiveSeconds)
            Toggle("show notification when a period is done",
                   isOn: $settings.showNotifications)
            HStack {
                Button("Test alarm") { engine.testAlarm() }
                Button("Stop") { engine.stopAlarm() }
            }
        }
    }

    private var menuBarSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("menu bar icon:").font(.headline)
                Picker("", selection: $settings.menuBarMode) {
                    ForEach(MenuBarMode.allCases) { mode in
                        Text(mode.label).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
            }
            Toggle("increase contrast", isOn: $settings.increaseContrast)
        }
    }

    private var floatingTimerSection: some View {
        Toggle("show floating timer", isOn: $settings.showFloatingTimer)
    }

    private var launchSection: some View {
        Toggle("launch at login", isOn: $settings.launchAtLogin)
    }

    // MARK: - Reusable controls

    private func presetStepper(index: Int) -> some View {
        Stepper(value: presetBinding(index), in: SettingsDefault.minMinutes...SettingsDefault.maxMinutes) {
            Text("\(settings.presets[index])")
                .frame(minWidth: 24, alignment: .trailing)
                .monospacedDigit()
        }
    }

    private func minuteStepper(_ label: String, value: Binding<Int>) -> some View {
        Stepper(value: value, in: SettingsDefault.minMinutes...SettingsDefault.maxMinutes) {
            Text("\(label): \(value.wrappedValue)")
        }
    }

    private func presetBinding(_ index: Int) -> Binding<Int> {
        Binding(
            get: { settings.presets[index] },
            set: { newValue in
                var updated = settings.presets
                guard index < updated.count else { return }
                updated[index] = newValue
                settings.presets = updated
            }
        )
    }
}
