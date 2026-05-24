import Foundation

struct Sport: Identifiable, Hashable, Codable {
    let id: String
    let slug: String
    let name: String
    let symbol: String

    static let all: [Sport] = [
        .init(id: "soccer", slug: "soccer", name: "Soccer", symbol: "soccerball"),
        .init(id: "boxing", slug: "boxing", name: "Boxing", symbol: "figure.boxing"),
        .init(id: "mma", slug: "mma", name: "MMA", symbol: "figure.martial.arts"),
        .init(id: "nba", slug: "nba", name: "NBA", symbol: "basketball.fill"),
        .init(id: "nfl", slug: "nfl", name: "NFL", symbol: "football.fill"),
        .init(id: "mlb", slug: "mlb", name: "MLB", symbol: "baseball.fill"),
    ]
}
