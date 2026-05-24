import Foundation
import SwiftUI

@Observable
final class AppEnvironment {
    static let shared = AppEnvironment()

    var apiBaseURL: URL = URL(string: "https://api.slate.app/v1")!
    var country: Country {
        didSet { UserDefaults.standard.set(country.code, forKey: "country") }
    }

    private init() {
        let stored = UserDefaults.standard.string(forKey: "country") ?? Locale.current.region?.identifier ?? "DE"
        self.country = Country.supported.first(where: { $0.code == stored }) ?? .germany
    }
}

struct Country: Identifiable, Hashable {
    var id: String { code }
    let code: String
    let name: String
    let flag: String

    static let germany = Country(code: "DE", name: "Germany", flag: "🇩🇪")
    static let unitedStates = Country(code: "US", name: "United States", flag: "🇺🇸")
    static let unitedKingdom = Country(code: "GB", name: "United Kingdom", flag: "🇬🇧")

    static let supported: [Country] = [.germany, .unitedStates, .unitedKingdom]
}
