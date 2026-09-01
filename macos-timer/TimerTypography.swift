import SwiftUI

enum PanelLayout {
    static let width: CGFloat = 320
    static let height: CGFloat = 152
    static let contentHeight: CGFloat = 120
    static let cornerRadius: CGFloat = 16
}

enum TimerTheme {
    static let panelBorder = Color("PanelBorder")
    static let tick = Color("TimerTick")
    static let indicator = Color("TimerIndicator")
    static let label = Color("TimerLabel")
    static let labelMuted = Color("TimerLabelMuted")

    static let tickHeight: CGFloat = 34
    static let tickLineWidth: CGFloat = 1
}

enum TimerTypography {
    static func display(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight)
    }

    static let menuBar = display(size: 13, weight: .medium)
    static let preset = display(size: 13, weight: .medium)
    static let action = display(size: 15, weight: .medium)
    static let readout = display(size: 40, weight: .regular)
}
