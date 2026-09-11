import SwiftUI

struct PomodoroView: View {
    @EnvironmentObject private var pomodoro: PomodoroModel
    @EnvironmentObject private var coordinator: AppCoordinator

    var body: some View {
        Group {
            if pomodoro.isSessionActive {
                activeSessionView
            } else {
                presetListView
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .padding(.horizontal, 10)
        .padding(.bottom, 6)
        .sheet(isPresented: $pomodoro.isEditorPresented) {
            if pomodoro.editingPreset != nil {
                PomodoroPresetEditorView(
                    preset: Binding(
                        get: { pomodoro.editingPreset ?? PomodoroPreset.newDraft() },
                        set: { pomodoro.editingPreset = $0 }
                    ),
                    onSave: { pomodoro.saveEditingPreset() },
                    onCancel: {
                        pomodoro.isEditorPresented = false
                        pomodoro.editingPreset = nil
                    }
                )
            }
        }
    }

    private var presetListView: some View {
        VStack(alignment: .leading, spacing: 4) {
            ScrollView {
                VStack(spacing: 4) {
                    ForEach(pomodoro.presets) { preset in
                        presetRow(preset)
                    }
                }
            }

            Button("+") {
                pomodoro.createPreset()
            }
            .buttonStyle(SharedPresetButtonStyle())
        }
    }

    private func presetRow(_ preset: PomodoroPreset) -> some View {
        HStack(spacing: 8) {
            Button {
                coordinator.startPomodoro(preset: preset)
            } label: {
                HStack(spacing: 6) {
                    Text(preset.name)
                        .font(TimerTypography.preset)
                        .foregroundStyle(TimerTheme.label)
                    Text(preset.summary)
                        .font(TimerTypography.preset)
                        .foregroundStyle(TimerTheme.labelMuted)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)

            Button {
                pomodoro.editPreset(preset)
            } label: {
                Image(systemName: "pencil")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(TimerTheme.label)
            }
            .buttonStyle(.plain)

            Button {
                pomodoro.deletePreset(preset)
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(TimerTheme.labelMuted)
            }
            .buttonStyle(.plain)
        }
        .contextMenu {
            Button("edit") {
                pomodoro.editPreset(preset)
            }
            Button("delete", role: .destructive) {
                pomodoro.deletePreset(preset)
            }
        }
    }

    private var activeSessionView: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Text(pomodoro.phase.title)
                    .font(TimerTypography.preset)
                    .foregroundStyle(TimerTheme.label)

                roundDots

                Spacer()

                Text(pomodoro.roundLabel)
                    .font(TimerTypography.preset)
                    .foregroundStyle(TimerTheme.labelMuted)
            }

            DurationScrubberView(
                seconds: Binding(
                    get: { max(TimerModel.minDuration, pomodoro.remainingSeconds) },
                    set: { _ in }
                ),
                isEnabled: false
            )
            .frame(maxWidth: .infinity)

            HStack(alignment: .lastTextBaseline, spacing: 12) {
                Button(pomodoro.primaryActionTitle) {
                    pomodoro.primaryAction()
                }
                .buttonStyle(SharedActionButtonStyle())
                .disabled(pomodoro.sessionState == .finished)

                Button("finish") {
                    pomodoro.stopSession()
                }
                .buttonStyle(SharedSecondaryActionButtonStyle())

                Button("skip") {
                    pomodoro.skipPhase()
                }
                .buttonStyle(SharedSecondaryActionButtonStyle())

                Spacer()

                Text(TimerModel.formatTime(pomodoro.remainingSeconds))
                    .font(TimerTypography.readout)
                    .monospacedDigit()
                    .foregroundStyle(TimerTheme.label)
                    .contentTransition(.numericText())
            }
        }
    }

    private var roundDots: some View {
        HStack(spacing: 4) {
            ForEach(1...pomodoro.roundsInCycle, id: \.self) { round in
                Circle()
                    .fill(round <= pomodoro.currentRound ? TimerTheme.label : TimerTheme.labelMuted.opacity(0.35))
                    .frame(width: 5, height: 5)
            }
        }
    }
}
