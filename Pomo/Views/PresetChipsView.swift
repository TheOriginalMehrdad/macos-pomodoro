//
//  PresetChipsView.swift
//  Pomo
//
//  The quick-pick preset row (e.g. "5m  10m  25m") plus an overflow menu.
//

import SwiftUI

struct PresetChipsView: View {
    let presets: [Int]
    let highContrast: Bool
    let onSelect: (Int) -> Void

    var body: some View {
        HStack(spacing: 22) {
            ForEach(presets, id: \.self) { minutes in
                Button {
                    onSelect(minutes)
                } label: {
                    Text("\(minutes)m")
                        .font(.title3)
                        .foregroundStyle(.white.opacity(highContrast ? 1 : 0.85))
                }
                .buttonStyle(.plain)
            }
        }
    }
}
