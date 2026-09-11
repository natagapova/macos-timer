import SwiftUI

struct DurationScrubberView: View {
    @Binding var seconds: Int
    let isEnabled: Bool

    private let minSeconds = TimerModel.minDuration
    private let maxSeconds = TimerModel.maxDuration

    var body: some View {
        GeometryReader { geometry in
            let width = max(geometry.size.width, 1)
            let fraction = CGFloat(seconds - minSeconds) / CGFloat(maxSeconds - minSeconds)
            let indicatorX = fraction * width

            Canvas { context, size in
                drawTicks(in: context, size: size, indicatorX: indicatorX)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        guard isEnabled else { return }
                        updateSelection(at: value.location.x, width: width)
                    }
            )
        }
        .frame(height: 48)
        .opacity(isEnabled ? 1 : 0.45)
    }

    private func updateSelection(at x: CGFloat, width: CGFloat) {
        let fraction = min(max(x / width, 0), 1)
        let minMinutes = minSeconds / 60
        let maxMinutes = maxSeconds / 60
        let minutes = minMinutes + Int((fraction * Double(maxMinutes - minMinutes)).rounded())
        seconds = minutes * 60
    }

    private func drawTicks(in context: GraphicsContext, size: CGSize, indicatorX: CGFloat) {
        let span = maxSeconds - minSeconds
        let step = 60

        for tick in stride(from: 0, through: span, by: step) {
            let x = CGFloat(tick) / CGFloat(span) * size.width
            drawTick(at: x, color: TimerTheme.tick, in: context, size: size)
        }

        drawTick(at: indicatorX, color: TimerTheme.indicator, in: context, size: size)
    }

    private func drawTick(at x: CGFloat, color: Color, in context: GraphicsContext, size: CGSize) {
        var path = Path()
        path.move(to: CGPoint(x: x, y: size.height))
        path.addLine(to: CGPoint(x: x, y: size.height - TimerTheme.tickHeight))

        context.stroke(
            path,
            with: .color(color),
            style: StrokeStyle(lineWidth: TimerTheme.tickLineWidth, lineCap: .butt)
        )
    }
}
