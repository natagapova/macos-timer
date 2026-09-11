import SwiftUI

struct SharedPresetButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(TimerTypography.preset)
            .foregroundStyle(TimerTheme.label)
            .opacity(configuration.isPressed ? 0.65 : 1)
    }
}

struct SharedActionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(TimerTypography.action)
            .foregroundStyle(TimerTheme.label)
            .opacity(configuration.isPressed ? 0.65 : 1)
    }
}

struct SharedSecondaryActionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(TimerTypography.preset)
            .foregroundStyle(TimerTheme.labelMuted)
            .opacity(configuration.isPressed ? 0.65 : 1)
    }
}
