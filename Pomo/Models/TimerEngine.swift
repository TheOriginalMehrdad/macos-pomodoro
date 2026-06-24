//
//  TimerEngine.swift
//  Pomo
//
//  Drives the Pomodoro cycle: focus -> break -> focus, with a 1s ticker.
//

import Foundation
import Combine
import SwiftUI

/// The three Pomodoro phases.
enum Phase: String {
    case focus
    case shortBreak
    case longBreak

    var title: String {
        switch self {
        case .focus: return "Focus"
        case .shortBreak: return "Short Break"
        case .longBreak: return "Long Break"
        }
    }

    var tint: Color {
        switch self {
        case .focus: return .orange
        case .shortBreak: return .teal
        case .longBreak: return .blue
        }
    }
}

/// Owns the live countdown and phase transitions. MainActor-isolated (UI state).
final class TimerEngine: ObservableObject {
    @Published private(set) var phase: Phase = .focus
    @Published private(set) var remaining: Int
    @Published private(set) var isRunning = false
    @Published private(set) var completedFocusSessions = 0

    private let settings: AppSettings
    private let alarm: AlarmPlayer
    private var ticker: Timer?
    private var cancellables = Set<AnyCancellable>()

    private static let secondsPerMinute = 60

    init(settings: AppSettings, alarm: AlarmPlayer = AlarmPlayer()) {
        self.settings = settings
        self.alarm = alarm
        self.remaining = settings.focusMinutes * TimerEngine.secondsPerMinute
        observeIdleFocusDuration()
    }

    // MARK: - Derived state

    /// Remaining time formatted as MM:SS.
    var displayString: String {
        let minutes = remaining / TimerEngine.secondsPerMinute
        let seconds = remaining % TimerEngine.secondsPerMinute
        return String(format: "%02d:%02d", minutes, seconds)
    }

    /// Full length of the current phase, in seconds.
    var currentPhaseDuration: Int { duration(for: phase) }

    /// Progress 0...1 through the current phase.
    var progress: Double {
        let total = currentPhaseDuration
        guard total > 0 else { return 0 }
        return Double(total - remaining) / Double(total)
    }

    // MARK: - Controls

    func toggle() { isRunning ? pause() : start() }

    func start() {
        alarm.stop()
        beginCountdown()
    }

    /// Start ticking the current phase without silencing a ringing alarm.
    /// Used when auto-advancing so the end-of-phase alarm keeps playing
    /// (until auto-mute) as the next phase begins.
    private func beginCountdown() {
        if remaining <= 0 { remaining = currentPhaseDuration }
        guard !isRunning else { return }
        isRunning = true
        startTicker()
    }

    func pause() {
        isRunning = false
        stopTicker()
    }

    func reset() {
        alarm.stop()
        pause()
        remaining = currentPhaseDuration
    }

    /// Move to the next phase immediately without ringing the alarm.
    func skip() {
        alarm.stop()
        pause()
        transition(countCompletedFocus: false)
        remaining = currentPhaseDuration
    }

    /// Play the alarm now using current settings (for the Settings "Test alarm" button).
    func testAlarm() {
        alarm.play(volume: settings.alarmVolume,
                   autoMute: settings.autoMuteAfterFiveSeconds)
    }

    /// Stop the alarm if it is currently ringing.
    func stopAlarm() {
        alarm.stop()
    }

    /// Set the focus length from the scrubber / presets (only meaningful while idle in focus).
    func setFocusMinutes(_ minutes: Int) {
        let clamped = min(max(minutes, SettingsDefault.minMinutes), SettingsDefault.maxMinutes)
        settings.focusMinutes = clamped
        if phase == .focus && !isRunning {
            remaining = clamped * TimerEngine.secondsPerMinute
        }
    }

    // MARK: - Ticking

    private func startTicker() {
        stopTicker()
        let timer = Timer(timeInterval: 1, repeats: true) { [weak self] _ in
            self?.tick()
        }
        RunLoop.main.add(timer, forMode: .common)
        ticker = timer
    }

    private func stopTicker() {
        ticker?.invalidate()
        ticker = nil
    }

    private func tick() {
        guard remaining > 1 else {
            remaining = 0
            completePhase()
            return
        }
        remaining -= 1
    }

    // MARK: - Phase transitions

    private func completePhase() {
        stopTicker()
        isRunning = false
        alarm.play(volume: settings.alarmVolume,
                   autoMute: settings.autoMuteAfterFiveSeconds)
        let finished = phase
        transition(countCompletedFocus: true)
        if settings.showNotifications {
            Notifier.shared.notifyPhaseChange(finished: finished, next: phase)
        }
        remaining = currentPhaseDuration
        if settings.autoStartNextPhase { beginCountdown() }
    }

    /// Advance `phase` to the next one in the cycle.
    private func transition(countCompletedFocus: Bool) {
        switch phase {
        case .focus:
            if countCompletedFocus { completedFocusSessions += 1 }
            let isLong = completedFocusSessions > 0
                && completedFocusSessions % settings.sessionsPerLongBreak == 0
            phase = isLong ? .longBreak : .shortBreak
        case .shortBreak, .longBreak:
            phase = .focus
        }
    }

    private func duration(for phase: Phase) -> Int {
        let minutes: Int
        switch phase {
        case .focus: minutes = settings.focusMinutes
        case .shortBreak: minutes = settings.shortBreakMinutes
        case .longBreak: minutes = settings.longBreakMinutes
        }
        return minutes * TimerEngine.secondsPerMinute
    }

    /// Keep the displayed focus countdown in sync when the user edits durations
    /// in Settings while idle.
    private func observeIdleFocusDuration() {
        settings.$focusMinutes
            .dropFirst()
            .sink { [weak self] minutes in
                guard let self, self.phase == .focus, !self.isRunning else { return }
                self.remaining = minutes * TimerEngine.secondsPerMinute
            }
            .store(in: &cancellables)
    }
}
