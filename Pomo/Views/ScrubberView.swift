//
//  ScrubberView.swift
//  Pomo
//
//  A ruler-style tick scrubber for setting the focus duration by dragging,
//  mirroring the reference design (fine ticks, taller ticks every 5 min,
//  a white playhead at the selected value).
//

import SwiftUI

struct ScrubberView: View {
    /// Selected minutes (bound to the engine's focus length).
    @Binding var minutes: Int
    var highContrast: Bool = false

    private let maxMinutes = SettingsDefault.maxMinutes
    private let minMinutes = SettingsDefault.minMinutes

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let height = geo.size.height
            Canvas { context, size in
                draw(in: context, size: size)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        update(fromX: value.location.x, width: width)
                    }
            )
            .frame(height: height)
        }
        .frame(height: 56)
    }

    private func update(fromX x: CGFloat, width: CGFloat) {
        guard width > 0 else { return }
        let fraction = min(max(x / width, 0), 1)
        let value = Int((fraction * CGFloat(maxMinutes)).rounded())
        minutes = min(max(value, minMinutes), maxMinutes)
    }

    private func draw(in context: GraphicsContext, size: CGSize) {
        let tickColor = Color.white.opacity(highContrast ? 0.55 : 0.32)
        for tick in 0...maxMinutes {
            let x = size.width * CGFloat(tick) / CGFloat(maxMinutes)
            let isMajor = tick % 5 == 0
            let tickHeight = size.height * (isMajor ? 0.62 : 0.34)
            let y = (size.height - tickHeight) / 2
            var path = Path()
            path.move(to: CGPoint(x: x, y: y))
            path.addLine(to: CGPoint(x: x, y: y + tickHeight))
            context.stroke(path, with: .color(tickColor), lineWidth: 1)
        }
        drawPlayhead(in: context, size: size)
    }

    private func drawPlayhead(in context: GraphicsContext, size: CGSize) {
        let x = size.width * CGFloat(minutes) / CGFloat(maxMinutes)
        var path = Path()
        path.move(to: CGPoint(x: x, y: 2))
        path.addLine(to: CGPoint(x: x, y: size.height - 2))
        context.stroke(path, with: .color(.white), lineWidth: 3)
    }
}
