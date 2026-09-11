import SwiftUI

struct TimerView: View {
    @EnvironmentObject private var timer: TimerModel
    @EnvironmentObject private var coordinator: AppCoordinator

    private let presets = [5, 10, 15, 30, 45, 60]

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            DurationScrubberView(
                seconds: Binding(
                    get: { timer.selectedSeconds },
                    set: { timer.setDuration($0) }
                ),
                isEnabled: timer.isEditable
            )
            .frame(maxWidth: .infinity)

            presetRow

            bottomRow
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .padding(.horizontal, 10)
        .padding(.bottom, 6)
        .onAppear {
            timer.requestNotificationPermission()
        }
    }

    private var presetRow: some View {
        HStack(spacing: 0) {
            HStack(spacing: 16) {
                ForEach(presets, id: \.self) { minutes in
                    Button(presetLabel(for: minutes)) {
                        timer.setPreset(minutes: minutes)
                    }
                    .buttonStyle(PresetButtonStyle())
                    .disabled(!timer.isEditable)
                }
            }

            Spacer(minLength: 8)

            TimerSettingsMenu()
        }
        .frame(maxWidth: .infinity)
    }

    private var bottomRow: some View {
        HStack(alignment: .lastTextBaseline, spacing: 12) {
            Button(primaryActionTitle) {
                performPrimaryAction()
            }
            .buttonStyle(ActionButtonStyle())

            if !timer.isEditable {
                Button("finish") {
                    timer.reset()
                }
                .buttonStyle(SecondaryActionButtonStyle())
            }

            Spacer()

            Text(TimerModel.formatTime(timer.readoutSeconds))
                .font(TimerTypography.readout)
                .monospacedDigit()
                .foregroundStyle(TimerTheme.label)
                .contentTransition(.numericText())
        }
    }

    private func presetLabel(for minutes: Int) -> String {
        minutes == 60 ? "1h" : "\(minutes)m"
    }

    private var primaryActionTitle: String {
        switch timer.state {
        case .idle, .finished:
            return "start"
        case .running:
            return "pause"
        case .paused:
            return "resume"
        }
    }

    private func performPrimaryAction() {
        switch timer.state {
        case .idle, .finished:
            timer.start()
        case .running:
            timer.pause()
        case .paused:
            timer.start()
        }
    }
}

private struct TimerSettingsMenu: View {
    @EnvironmentObject private var timer: TimerModel
    @EnvironmentObject private var coordinator: AppCoordinator

    var body: some View {
        Menu {
            Menu("sound") {
                ForEach(CompletionSound.allCases) { sound in
                    soundButton(sound)
                }
            }

            Menu("theme") {
                ForEach(AppAppearance.allCases) { theme in
                    themeButton(theme)
                }
            }

            Button("quit") {
                NSApplication.shared.terminate(nil)
            }
        } label: {
            Image(systemName: "ellipsis")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(TimerTheme.labelMuted)
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .fixedSize()
    }

    private func themeButton(_ theme: AppAppearance) -> some View {
        Button {
            coordinator.setAppearance(theme)
        } label: {
            if coordinator.appearance == theme {
                Label(theme.label, systemImage: "checkmark")
            } else {
                Text(theme.label)
            }
        }
    }

    private func soundButton(_ sound: CompletionSound) -> some View {
        Button {
            timer.setCompletionSound(sound)
        } label: {
            if timer.completionSound == sound {
                Label(sound.label, systemImage: "checkmark")
            } else {
                Text(sound.label)
            }
        }
    }
}

private struct PresetButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(TimerTypography.preset)
            .foregroundStyle(TimerTheme.label)
            .opacity(configuration.isPressed ? 0.65 : 1)
    }
}

private struct ActionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(TimerTypography.action)
            .foregroundStyle(TimerTheme.label)
            .opacity(configuration.isPressed ? 0.65 : 1)
    }
}

private struct SecondaryActionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(TimerTypography.preset)
            .foregroundStyle(TimerTheme.labelMuted)
            .opacity(configuration.isPressed ? 0.65 : 1)
    }
}
