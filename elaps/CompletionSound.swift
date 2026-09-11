import AppKit
import Foundation

enum CompletionSound: String, CaseIterable, Identifiable, Codable {
    case none
    case glass
    case ping
    case pop
    case submarine
    case pluck
    case cricket

    var id: String { rawValue }

    var label: String { rawValue }

    func play() {
        switch source {
        case .none:
            return
        case .system(let name):
            if let sound = NSSound(named: name) {
                sound.play()
            } else {
                NSSound.beep()
            }
        case .bundled(let filename):
            guard
                let url = bundledURL(for: filename),
                let sound = NSSound(contentsOf: url, byReference: true)
            else {
                NSSound.beep()
                return
            }
            sound.play()
        }
    }

    private enum Source {
        case none
        case system(String)
        case bundled(String)
    }

    private var source: Source {
        switch self {
        case .none: return .none
        case .glass: return .system("Glass")
        case .ping: return .system("Ping")
        case .pop: return .system("Pop")
        case .submarine: return .system("Submarine")
        case .pluck: return .bundled("pluck.wav")
        case .cricket: return .bundled("cricket.wav")
        }
    }

    private func bundledURL(for filename: String) -> URL? {
        let base = (filename as NSString).deletingPathExtension
        let ext = (filename as NSString).pathExtension

        if let url = Bundle.main.url(forResource: base, withExtension: ext, subdirectory: "Sounds") {
            return url
        }

        return Bundle.main.url(forResource: base, withExtension: ext)
    }
}

struct CompletionSoundStore {
    private let key = "timer.completionSound"

    func load() -> CompletionSound {
        guard
            let raw = UserDefaults.standard.string(forKey: key),
            let sound = CompletionSound(rawValue: raw)
        else {
            return .glass
        }
        return sound
    }

    func save(_ sound: CompletionSound) {
        UserDefaults.standard.set(sound.rawValue, forKey: key)
    }
}
