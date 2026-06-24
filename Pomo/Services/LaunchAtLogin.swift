//
//  LaunchAtLogin.swift
//  Pomo
//
//  Thin wrapper around SMAppService for the "launch at login" toggle.
//

import ServiceManagement

enum LaunchAtLogin {
    /// Whether the app is currently registered to launch at login.
    static var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    /// Register or unregister the app as a login item. Propagates failures.
    static func set(_ enabled: Bool) throws {
        if enabled {
            if SMAppService.mainApp.status != .enabled {
                try SMAppService.mainApp.register()
            }
        } else {
            if SMAppService.mainApp.status == .enabled {
                try SMAppService.mainApp.unregister()
            }
        }
    }
}
