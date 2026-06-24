//
//  Notifier.swift
//  Pomo
//
//  Best-effort user notifications when a phase ends. Defensive: any failure
//  (e.g. missing bundle identifier, denied authorization) is ignored so the
//  core timer keeps working.
//

import Foundation
import UserNotifications

final class Notifier {
    static let shared = Notifier()
    private var authorized = false

    private init() {}

    /// Request notification permission once, early in app launch.
    func requestAuthorization() {
        guard Bundle.main.bundleIdentifier != nil else { return }
        UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound]) { [weak self] granted, _ in
                self?.authorized = granted
            }
    }

    /// Post a notification announcing the phase that just finished and the next one.
    func notifyPhaseChange(finished: Phase, next: Phase) {
        guard authorized else { return }
        let content = UNMutableNotificationContent()
        content.title = "\(finished.title) complete"
        content.body = "Time for \(next.title.lowercased())."
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }
}
