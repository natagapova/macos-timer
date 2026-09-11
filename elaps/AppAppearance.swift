import AppKit
import Foundation

enum AppAppearance: String, CaseIterable, Identifiable, Codable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var label: String {
        switch self {
        case .system: return "default"
        case .light: return "light"
        case .dark: return "dark"
        }
    }

    var usesLightLogo: Bool {
        self == .light
    }

    func apply() {
        NSApp.appearance = nsAppearance
    }

    private var nsAppearance: NSAppearance? {
        switch self {
        case .system, .dark:
            return NSAppearance(named: .darkAqua)
        case .light:
            return NSAppearance(named: .aqua)
        }
    }
}

struct AppAppearanceStore {
    private let key = "app.appearance"

    func load() -> AppAppearance {
        guard
            let raw = UserDefaults.standard.string(forKey: key),
            let appearance = AppAppearance(rawValue: raw)
        else {
            return .system
        }
        return appearance
    }

    func save(_ appearance: AppAppearance) {
        UserDefaults.standard.set(appearance.rawValue, forKey: key)
    }
}
