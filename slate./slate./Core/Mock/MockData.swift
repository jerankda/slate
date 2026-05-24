import Foundation

enum MockData {
    static func events(for country: String = "DE") -> [Event] {
        let now = Date()
        func h(_ hours: Double) -> Date { now.addingTimeInterval(hours * 3600) }

        return [
            Event(id: "evt-1", sportSlug: "soccer", league: "Bundesliga",
                  title: "Bayern München vs Borussia Dortmund",
                  subtitle: "Der Klassiker",
                  startTimeUTC: h(3),
                  venue: "Allianz Arena, München",
                  broadcasts: [
                    .init(provider: "Sky Sport", countryCode: "DE", kind: .tv),
                    .init(provider: "DAZN", countryCode: "DE", kind: .stream),
                    .init(provider: "ESPN+", countryCode: "US", kind: .stream),
                    .init(provider: "Sky Sports", countryCode: "GB", kind: .tv),
                  ]),
            Event(id: "evt-2", sportSlug: "nba", league: "NBA",
                  title: "Lakers vs Celtics",
                  subtitle: "Rivalry Week",
                  startTimeUTC: h(8),
                  venue: "Crypto.com Arena",
                  broadcasts: [
                    .init(provider: "NBA League Pass", countryCode: country, kind: .stream),
                    .init(provider: "TNT", countryCode: "US", kind: .tv),
                  ]),
            Event(id: "evt-3", sportSlug: "soccer", league: "Premier League",
                  title: "Arsenal vs Manchester City",
                  subtitle: nil,
                  startTimeUTC: h(26),
                  venue: "Emirates Stadium",
                  broadcasts: [
                    .init(provider: "Sky Sports", countryCode: "GB", kind: .tv),
                    .init(provider: "Peacock", countryCode: "US", kind: .stream),
                    .init(provider: "Sky Sport", countryCode: "DE", kind: .tv),
                  ]),
            Event(id: "evt-4", sportSlug: "boxing", league: nil,
                  title: "Fury vs Usyk II",
                  subtitle: "Heavyweight Unification",
                  startTimeUTC: h(36),
                  venue: "Kingdom Arena, Riyadh",
                  broadcasts: [
                    .init(provider: "DAZN PPV", countryCode: country, kind: .ppv),
                  ]),
            Event(id: "evt-5", sportSlug: "mma", league: "UFC 312",
                  title: "Du Plessis vs Strickland 2",
                  subtitle: "Middleweight Title",
                  startTimeUTC: h(60),
                  venue: "Qudos Bank Arena, Sydney",
                  broadcasts: [
                    .init(provider: "TNT Sports", countryCode: country, kind: .tv),
                    .init(provider: "ESPN+", countryCode: "US", kind: .ppv),
                  ]),
            Event(id: "evt-6", sportSlug: "nfl", league: "NFL",
                  title: "Chiefs vs Eagles",
                  subtitle: "Super Bowl LIX Rematch",
                  startTimeUTC: h(72),
                  venue: "Arrowhead Stadium",
                  broadcasts: [
                    .init(provider: "DAZN", countryCode: country, kind: .stream),
                    .init(provider: "CBS", countryCode: "US", kind: .tv),
                  ]),
            Event(id: "evt-7", sportSlug: "soccer", league: "Champions League",
                  title: "Real Madrid vs PSG",
                  subtitle: "Quarter-final, 1st leg",
                  startTimeUTC: h(96),
                  venue: "Santiago Bernabéu",
                  broadcasts: [
                    .init(provider: "DAZN", countryCode: country, kind: .stream),
                  ]),
            Event(id: "evt-8", sportSlug: "mlb", league: "MLB",
                  title: "Yankees vs Dodgers",
                  subtitle: nil,
                  startTimeUTC: h(120),
                  venue: "Yankee Stadium",
                  broadcasts: [
                    .init(provider: "MLB.TV", countryCode: country, kind: .stream),
                  ]),
            Event(id: "evt-9", sportSlug: "nba", league: "NBA",
                  title: "Warriors vs Nuggets",
                  subtitle: nil,
                  startTimeUTC: h(168),
                  venue: "Chase Center",
                  broadcasts: [
                    .init(provider: "NBA League Pass", countryCode: country, kind: .stream),
                  ]),
            Event(id: "evt-10", sportSlug: "soccer", league: "La Liga",
                  title: "Barcelona vs Atlético Madrid",
                  subtitle: nil,
                  startTimeUTC: h(192),
                  venue: "Camp Nou",
                  broadcasts: [
                    .init(provider: "DAZN", countryCode: "DE", kind: .stream),
                    .init(provider: "ESPN+", countryCode: "US", kind: .stream),
                  ]),
        ]
    }
}
