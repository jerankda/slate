import Foundation

/// Tiny disk cache for the last successful backend response per country.
/// Lets the app open instantly with the previous slate even when offline.
enum EventCache {
    private static let dirName = "slate-cache"

    private static var cacheDir: URL? {
        guard let base = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else { return nil }
        let dir = base.appending(path: dirName)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    private static func fileURL(country: String) -> URL? {
        cacheDir?.appending(path: "events-\(country.uppercased()).json")
    }

    static func load(country: String) -> (events: [Event], savedAt: Date)? {
        guard let url = fileURL(country: country),
              let data = try? Data(contentsOf: url) else { return nil }
        let decoder = JSONDecoder(); decoder.dateDecodingStrategy = .iso8601
        struct Envelope: Codable { let savedAt: Date; let events: [Event] }
        guard let env = try? decoder.decode(Envelope.self, from: data) else { return nil }
        return (env.events, env.savedAt)
    }

    static func save(_ events: [Event], country: String) {
        guard let url = fileURL(country: country) else { return }
        let encoder = JSONEncoder(); encoder.dateEncodingStrategy = .iso8601
        struct Envelope: Codable { let savedAt: Date; let events: [Event] }
        guard let data = try? encoder.encode(Envelope(savedAt: .now, events: events)) else { return }
        try? data.write(to: url, options: .atomic)
    }

    static func clear() {
        guard let dir = cacheDir else { return }
        try? FileManager.default.removeItem(at: dir)
    }
}
