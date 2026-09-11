import Foundation

struct PomodoroPreset: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var workMinutes: Int
    var breakMinutes: Int
    var longBreakMinutes: Int
    var roundsBeforeLongBreak: Int
    var autoAdvance: Bool

    static let classic = PomodoroPreset(
        id: UUID(uuidString: "A1000000-0000-0000-0000-000000000001")!,
        name: "classic",
        workMinutes: 25,
        breakMinutes: 5,
        longBreakMinutes: 15,
        roundsBeforeLongBreak: 4,
        autoAdvance: true
    )

    var summary: String {
        "\(workMinutes)m work · \(breakMinutes)m break · long \(longBreakMinutes)m"
    }

    static func newDraft() -> PomodoroPreset {
        PomodoroPreset(
            id: UUID(),
            name: "custom",
            workMinutes: 25,
            breakMinutes: 5,
            longBreakMinutes: 15,
            roundsBeforeLongBreak: 4,
            autoAdvance: true
        )
    }
}
