//
//  AppSettings.swift
//  Pomo
//
//  User-configurable preferences, persisted in UserDefaults.
//

import Foundation
import Combine

/// How the menu bar item is rendered.
enum MenuBarMode: String, CaseIterable, Identifiable {
    case compact   // icon only
    case expanded  // live countdown pill

    var id: String { rawValue }
    var label: String { self == .compact ? "compact" : "expanded" }
}

/// Default values, kept as named constants (no magic numbers scattered in code).
enum SettingsDefault {
    static let focusMinutes = 25
    static let shortBreakMinutes = 5
    static let longBreakMinutes = 15
    static let sessionsPerLongBreak = 4
    static let presets = [5, 10, 25]
    static let alarmVolume = 0.7
    static let autoMuteAfterFiveSeconds = true
    static let showNotifications = true
    static let menuBarMode = MenuBarMode.expanded
    static let increaseContrast = false
    static let autoStartNextPhase = true
    static let showFloatingTimer = false

    static let minMinutes = 1
    static let maxMinutes = 90
    static let presetCount = 3
}

/// Observable wrapper over `UserDefaults`. Each property persists on write.
final class AppSettings: ObservableObject {
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        defaults.register(defaults: AppSettings.registrationValues)
        self.focusMinutes = defaults.integer(forKey: Key.focusMinutes)
        self.shortBreakMinutes = defaults.integer(forKey: Key.shortBreakMinutes)
        self.longBreakMinutes = defaults.integer(forKey: Key.longBreakMinutes)
        self.sessionsPerLongBreak = defaults.integer(forKey: Key.sessionsPerLongBreak)
        self.presets = (defaults.array(forKey: Key.presets) as? [Int]) ?? SettingsDefault.presets
        self.alarmVolume = defaults.double(forKey: Key.alarmVolume)
        self.autoMuteAfterFiveSeconds = defaults.bool(forKey: Key.autoMute)
        self.showNotifications = defaults.bool(forKey: Key.showNotifications)
        self.menuBarMode = MenuBarMode(rawValue: defaults.string(forKey: Key.menuBarMode) ?? "")
            ?? SettingsDefault.menuBarMode
        self.increaseContrast = defaults.bool(forKey: Key.increaseContrast)
        self.autoStartNextPhase = defaults.bool(forKey: Key.autoStart)
        self.showFloatingTimer = defaults.bool(forKey: Key.showFloatingTimer)
        self.launchAtLogin = LaunchAtLogin.isEnabled
    }

    @Published var focusMinutes: Int { didSet { persist(focusMinutes, Key.focusMinutes) } }
    @Published var shortBreakMinutes: Int { didSet { persist(shortBreakMinutes, Key.shortBreakMinutes) } }
    @Published var longBreakMinutes: Int { didSet { persist(longBreakMinutes, Key.longBreakMinutes) } }
    @Published var sessionsPerLongBreak: Int { didSet { persist(sessionsPerLongBreak, Key.sessionsPerLongBreak) } }
    @Published var presets: [Int] { didSet { persist(presets, Key.presets) } }
    @Published var alarmVolume: Double { didSet { persist(alarmVolume, Key.alarmVolume) } }
    @Published var autoMuteAfterFiveSeconds: Bool { didSet { persist(autoMuteAfterFiveSeconds, Key.autoMute) } }
    @Published var showNotifications: Bool { didSet { persist(showNotifications, Key.showNotifications) } }
    @Published var menuBarMode: MenuBarMode { didSet { persist(menuBarMode.rawValue, Key.menuBarMode) } }
    @Published var increaseContrast: Bool { didSet { persist(increaseContrast, Key.increaseContrast) } }
    @Published var autoStartNextPhase: Bool { didSet { persist(autoStartNextPhase, Key.autoStart) } }
    @Published var showFloatingTimer: Bool { didSet { persist(showFloatingTimer, Key.showFloatingTimer) } }

    /// Reflects the real login-item registration; writing it (un)registers the app.
    @Published var launchAtLogin: Bool {
        didSet { applyLaunchAtLogin(launchAtLogin, previous: oldValue) }
    }

    private func persist(_ value: Any, _ key: String) {
        defaults.set(value, forKey: key)
    }

    private func applyLaunchAtLogin(_ enabled: Bool, previous: Bool) {
        guard enabled != previous else { return }
        do {
            try LaunchAtLogin.set(enabled)
        } catch {
            // Revert the toggle so the UI mirrors the real state; surface the failure.
            NSLog("Pomo: failed to update launch-at-login: \(error.localizedDescription)")
            if launchAtLogin != previous { launchAtLogin = previous }
        }
    }

    private static var registrationValues: [String: Any] {
        [
            Key.focusMinutes: SettingsDefault.focusMinutes,
            Key.shortBreakMinutes: SettingsDefault.shortBreakMinutes,
            Key.longBreakMinutes: SettingsDefault.longBreakMinutes,
            Key.sessionsPerLongBreak: SettingsDefault.sessionsPerLongBreak,
            Key.presets: SettingsDefault.presets,
            Key.alarmVolume: SettingsDefault.alarmVolume,
            Key.autoMute: SettingsDefault.autoMuteAfterFiveSeconds,
            Key.showNotifications: SettingsDefault.showNotifications,
            Key.menuBarMode: SettingsDefault.menuBarMode.rawValue,
            Key.increaseContrast: SettingsDefault.increaseContrast,
            Key.autoStart: SettingsDefault.autoStartNextPhase,
            Key.showFloatingTimer: SettingsDefault.showFloatingTimer,
        ]
    }

    private enum Key {
        static let focusMinutes = "focusMinutes"
        static let shortBreakMinutes = "shortBreakMinutes"
        static let longBreakMinutes = "longBreakMinutes"
        static let sessionsPerLongBreak = "sessionsPerLongBreak"
        static let presets = "presets"
        static let alarmVolume = "alarmVolume"
        static let autoMute = "autoMuteAfterFiveSeconds"
        static let showNotifications = "showNotifications"
        static let menuBarMode = "menuBarMode"
        static let increaseContrast = "increaseContrast"
        static let autoStart = "autoStartNextPhase"
        static let showFloatingTimer = "showFloatingTimer"
    }
}
