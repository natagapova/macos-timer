import SwiftUI

struct PomodoroPresetEditorView: View {
    @Binding var preset: PomodoroPreset
    let onSave: () -> Void
    let onCancel: () -> Void

    @State private var commitHandlers: [() -> Void] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("preset")
                .font(TimerTypography.action)
                .foregroundStyle(TimerTheme.label)

            TextField("name", text: $preset.name)
                .textFieldStyle(.roundedBorder)

            minuteField(label: "work", value: $preset.workMinutes, range: 1...180)
            minuteField(label: "break", value: $preset.breakMinutes, range: 1...60)
            minuteField(label: "long break", value: $preset.longBreakMinutes, range: 1...60)
            roundsField

            Toggle("auto-advance phases", isOn: $preset.autoAdvance)

            HStack {
                Button("cancel") { onCancel() }
                    .buttonStyle(SharedSecondaryActionButtonStyle())
                Spacer()
                Button("save") {
                    commitHandlers.forEach { $0() }
                    onSave()
                }
                    .buttonStyle(SharedActionButtonStyle())
            }
        }
        .padding(16)
        .frame(width: 300)
        .background(.regularMaterial)
    }

    private func minuteField(label: String, value: Binding<Int>, range: ClosedRange<Int>) -> some View {
        HStack(spacing: 8) {
            Text(label)
                .font(TimerTypography.preset)
                .foregroundStyle(TimerTheme.label)
                .frame(width: 72, alignment: .leading)

            EditableIntField(value: value, placeholder: "min", range: range, onRegisterCommit: registerCommit)
                .frame(width: 52)

            Text("m")
                .font(TimerTypography.preset)
                .foregroundStyle(TimerTheme.labelMuted)
        }
    }

    private var roundsField: some View {
        HStack(spacing: 8) {
            Text("rounds")
                .font(TimerTypography.preset)
                .foregroundStyle(TimerTheme.label)
                .frame(width: 72, alignment: .leading)

            EditableIntField(
                value: $preset.roundsBeforeLongBreak,
                placeholder: "rounds",
                range: 1...12,
                onRegisterCommit: registerCommit
            )
            .frame(width: 52)
        }
    }

    private func registerCommit(_ handler: @escaping () -> Void) {
        commitHandlers.append(handler)
    }
}

private struct EditableIntField: View {
    @Binding var value: Int
    let placeholder: String
    let range: ClosedRange<Int>
    let onRegisterCommit: (@escaping () -> Void) -> Void

    @State private var text = ""
    @State private var didRegisterCommit = false
    @FocusState private var isFocused: Bool

    var body: some View {
        TextField(placeholder, text: $text)
            .textFieldStyle(.roundedBorder)
            .multilineTextAlignment(.trailing)
            .focused($isFocused)
            .onAppear {
                syncFromValue()
                guard !didRegisterCommit else { return }
                didRegisterCommit = true
                onRegisterCommit(commit)
            }
            .onChange(of: value) { _ in
                if !isFocused {
                    syncFromValue()
                }
            }
            .onChange(of: isFocused) { focused in
                if !focused {
                    commit()
                }
            }
            .onChange(of: text) { newText in
                let filtered = String(newText.filter(\.isNumber))
                if filtered != newText {
                    text = filtered
                    return
                }
                applyTextToValue(filtered)
            }
            .onSubmit { commit() }
            .onDisappear { commit() }
    }

    private func syncFromValue() {
        text = String(value)
    }

    private func applyTextToValue(_ source: String) {
        guard !source.isEmpty, let parsed = Int(source) else { return }
        value = min(max(parsed, range.lowerBound), range.upperBound)
    }

    private func commit() {
        if text.isEmpty {
            syncFromValue()
            return
        }
        applyTextToValue(text)
        syncFromValue()
    }
}
