import SwiftUI

struct MenuBarTimerLabel: View {
    /// Fixed badge width for standard idle readouts like `30:00`.
    private static let gridReference = "30:00"

    let text: String

    private var sizingReference: String {
        text.count > Self.gridReference.count ? text : Self.gridReference
    }

    var body: some View {
        Text(sizingReference)
            .font(TimerTypography.menuBar)
            .monospacedDigit()
            .hidden()
            .overlay {
                Text(text)
                    .font(TimerTypography.menuBar)
                    .monospacedDigit()
                    .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(Color(nsColor: .labelColor).opacity(0.55), lineWidth: 1)
            }
    }
}
