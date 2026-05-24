import Foundation

/// Single source of truth for fetching events.
/// Tries backend → disk cache → bundled mock data, in that order.
@Observable
final class EventRepository {
    static let shared = EventRepository()

    enum Source: Equatable { case backend, cache, mock }
    private(set) var lastSource: Source = .mock
    private(set) var lastError: String?
    private(set) var lastSavedAt: Date?

    private let env = AppEnvironment.shared

    func sports() async -> [Sport] { Sport.all }

    /// Synchronous read of any previously-saved events for the given country.
    /// Lets views render instantly on launch before the network call returns.
    func cached(country: String) -> [Event] {
        guard let snapshot = EventCache.load(country: country) else { return [] }
        lastSavedAt = snapshot.savedAt
        return snapshot.events.sorted { $0.startTimeUTC < $1.startTimeUTC }
    }

    func events(sportSlug: String? = nil, country: String) async -> [Event] {
        let all = await fetchAll(country: country)
        if let slug = sportSlug { return all.filter { $0.sportSlug == slug } }
        return all
    }

    private func fetchAll(country: String) async -> [Event] {
        if env.useBackend, let base = env.apiBaseURL {
            let url = base
                .appending(path: "events")
                .appending(queryItems: [.init(name: "country", value: country)])
            do {
                let events: [Event] = try await APIClient.shared.get(url)
                let sorted = events.sorted { $0.startTimeUTC < $1.startTimeUTC }
                EventCache.save(sorted, country: country)
                lastSource = .backend
                lastError = nil
                lastSavedAt = .now
                return sorted
            } catch {
                // Backend failed — try cached snapshot before falling back to mock.
                if let snapshot = EventCache.load(country: country), !snapshot.events.isEmpty {
                    lastSource = .cache
                    lastError = "Offline — showing last update"
                    lastSavedAt = snapshot.savedAt
                    return snapshot.events.sorted { $0.startTimeUTC < $1.startTimeUTC }
                }
                lastError = "Backend unreachable — showing demo data"
            }
        } else {
            lastError = nil
        }
        lastSource = .mock
        lastSavedAt = nil
        return MockData.events(for: country).sorted { $0.startTimeUTC < $1.startTimeUTC }
    }
}
