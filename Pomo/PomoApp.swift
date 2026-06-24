//
//  PomoApp.swift
//  Pomo
//
//  Menu-bar-only Pomodoro app: a MenuBarExtra popover plus a Settings window.
//

import SwiftUI

@main
struct PomoApp: App {
    @StateObject private var settings: AppSettings
    @StateObject private var engine: TimerEngine

    init() {
        let settings = AppSettings()
        _settings = StateObject(wrappedValue: settings)
        _engine = StateObject(wrappedValue: TimerEngine(settings: settings))
        Notifier.shared.requestAuthorization()
    }

    var body: some Scene {
        MenuBarExtra {
            TimerPopoverView()
                .environmentObject(engine)
                .environmentObject(settings)
        } label: {
            MenuBarLabel(engine: engine, settings: settings)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
                .environmentObject(settings)
                .environmentObject(engine)
        }
    }
}
