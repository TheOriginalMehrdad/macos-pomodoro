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

    var body: some View {
        switch settings.menuBarMode {
        case .expanded:
            Text(engine.displayString)
                .monospacedDigit()
        case .compact:
            Image(systemName: engine.isRunning ? "timer" : "timer.circle")
        }
    }
}
