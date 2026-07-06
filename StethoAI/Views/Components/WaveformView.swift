import SwiftUI

/// Live-updating waveform visualizer driven by a rolling array of normalized (0...1) samples.
struct WaveformView: View {
    let samples: [Double]
    var color: Color = Tokens.Colors.primaryRed
    var lineWidth: CGFloat = 2.5

    var body: some View {
        Canvas { context, size in
            guard samples.count > 1 else { return }
            var path = Path()
            let stepX = size.width / CGFloat(samples.count - 1)
            for (index, sample) in samples.enumerated() {
                let x = CGFloat(index) * stepX
                let y = size.height - (CGFloat(sample) * size.height)
                if index == 0 {
                    path.move(to: CGPoint(x: x, y: y))
                } else {
                    path.addLine(to: CGPoint(x: x, y: y))
                }
            }
            context.stroke(path, with: .color(color), lineWidth: lineWidth)
        }
    }
}
