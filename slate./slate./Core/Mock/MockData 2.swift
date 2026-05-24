import Foundation

enum MockData {
    static func events(for country: String = "DE") -> [Event] {
        let now = Date()
        func t(_ hours: Double) -> Date { now.addingTimeInterval(hours * 3600) }

        return [
            Event(
                id: "evt-1",
                sportSlug: "soccer",
                league: "Bundesliga",
                title: "Bayern München vs Borussia Dortmund",
                subtitle: "Der Klassiker",
                startTimeUTC: t(6),
                venue: "Allianz Arena",
                broadcasts: [
                    .init(provider: "Sky Sport", countryCode: "DE", kind: .tv),
                    .init(provider: "DAZN", countryCode: "DE", kind: .stream),
                ]
            ),
            Event(
                id: "evt-2",
                sportSlug: "nba",
                league: "NBA",
                title: "Lakers vs Celtics",
                subtitle: nil,
                startTimeUTC: t(14),
                venue: "Crypto.com Arena",
                broadcasts: [
                    .init(provider: "NBA League Pass", countryCode: country, kind: .stream)
                ]
            ),
            Event(
                id: "evt-3",
                sportSlug: "boxing",
                league: nil,
                title: "Fury vs Usyk II",
                subtitle: "Heavyweight Unification",
                startTimeUTC: t(36),
                venue: "Kingdom Arena, Riyadh",
                broadcasts: [
                    .init(provider: "DAZN PPV", countryCode: country, kind: .ppv)
                ]
            ),
            Event(
                id: "evt-4",
                sportSlug: "mma",
                league: "UFC 312",
                title: "Du Plessis vs Strickland 2",
                subtitle: nil,
                startTimeUTC: t(60),
                venue: "Qudos Bank Arena",
                broadcasts: [
                    .init(provider: "TNT Sports", countryCode: country, kind: .tv)
                ]
            ),
            Event(
                id: "evt-5",
                sportSlug: "nfl",
                league: "NFL",
                title: "Chiefs vs Eagles",
                subtitle: "Super Bowl LIX Rematch",
                startTimeUTC: t(72),
                venue: "Arrowhead Stadium",
                broadcasts: [
                    .init(provider: "DAZN", countryCode: country, kind: .stream)
                ]
            ),
            Event(
                id: "evt-6",
                sportSlug: "mlb",
                league: "MLB",
                title: "Yankees vs Dodgers",
                subtitle: nil,
                startTimeUTC: t(96),
                venue: "Yankee Stadium",
                broadcasts: [
                    .init(provider: "MLB.TV", countryCode: country, kind: .stream)
                ]
            ),
        ]
    }
}
