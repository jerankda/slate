import Foundation

struct Event: Identifiable, Hashable, Codable {
    let id: String
    let sportSlug: String
    let league: String?
    let title: String
    let subtitle: String?
    let startTimeUTC: Date
    let venue: String?
    let broadcasts: [Broadcast]

    enum CodingKeys: String, CodingKey {
        case id, league, title, subtitle, venue, broadcasts
        case sportSlug = "sport_slug"
        case startTimeUTC = "start_time_utc"
    }

    /// Rough "is it on right now" check. We don't know exact durations, so we
    /// assume a generous 3.5h window from kickoff (covers soccer ET, NFL,
    /// boxing main cards, NBA OT, etc.).
    var isLive: Bool {
        let now = Date()
        let liveWindow: TimeInterval = 3.5 * 3600
        return now >= startTimeUTC && now < startTimeUTC.addingTimeInterval(liveWindow)
    }

    var hasStarted: Bool { Date() >= startTimeUTC }
}

struct Broadcast: Hashable, Codable {
    let provider: String
    let countryCode: String
    let kind: Kind

    enum Kind: String, Codable {
        case tv, stream, ppv
    }

    enum CodingKeys: String, CodingKey {
        case provider, kind
        case countryCode = "country_code"
    }
}
