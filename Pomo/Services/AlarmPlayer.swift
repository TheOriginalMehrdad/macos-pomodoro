//
//  AlarmPlayer.swift
//  Pomo
//
//  Plays the end-of-phase alarm using a bundled looping sound, with volume
//  control and optional auto-mute after a few seconds. AVAudioPlayer is used
//  (instead of NSSound named system sounds, which fail under App Sandbox).
//  The bundled alarm.wav is an original generated tone (no third-party audio).
//

import AppKit
import AVFoundation

final class AlarmPlayer {
    private var player: AVAudioPlayer?
    private var muteWorkItem: DispatchWorkItem?

    private static let resourceName = "alarm"
    private static let resourceExtension = "wav"
    private static let autoMuteDelay: TimeInterval = 5
    private static let playOnce = 0

    /// Start the alarm. `volume` is 0...1.
    func play(volume: Double, autoMute: Bool) {
        stop()
        guard let player = makePlayer() else {
            NSSound.beep()
            return
        }
        player.numberOfLoops = AlarmPlayer.playOnce
        player.volume = Float(min(max(volume, 0), 1))
        player.prepareToPlay()
        self.player = player
        player.play()
        if autoMute { scheduleMute() }
    }

    /// Stop any active alarm and cancel a pending auto-mute.
    func stop() {
        muteWorkItem?.cancel()
        muteWorkItem = nil
        player?.stop()
        player = nil
    }

    private func makePlayer() -> AVAudioPlayer? {
        guard let url = Bundle.main.url(forResource: AlarmPlayer.resourceName,
                                        withExtension: AlarmPlayer.resourceExtension) else {
            NSLog("Pomo: bundled alarm sound not found")
            return nil
        }
        do {
            return try AVAudioPlayer(contentsOf: url)
        } catch {
            NSLog("Pomo: failed to load alarm sound: \(error.localizedDescription)")
            return nil
        }
    }

    private func scheduleMute() {
        let work = DispatchWorkItem { [weak self] in self?.stop() }
        muteWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + AlarmPlayer.autoMuteDelay, execute: work)
    }
}
