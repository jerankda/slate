import Foundation
import SwiftUI

@Observable
final class AppEnvironment {
    static let shared = AppEnvironment()

    var useBackend: Bool {
        didSet { UserDefaults.standard.set(useBackend, forKey: Keys.useBackend) }
    }

    var apiBaseURLString: String {
        didSet { UserDefaults.standard.set(apiBaseURLString, forKey: Keys.apiBase) }
    }

    var apiBaseURL: URL? { URL(string: apiBaseURLString) }

    var country: Country {
        didSet { UserDefaults.standard.set(country.code, forKey: Keys.country) }
    }

    private enum Keys {
        static let country    = "country"
        static let apiBase    = "api_base_url"
        static let useBackend = "use_backend"
    }

    private init() {
        let ud = UserDefaults.standard
        let stored = ud.string(forKey: Keys.country) ?? Locale.current.region?.identifier ?? "DE"
        self.country = Country.supported.first(where: { $0.code == stored }) ?? .germany
        self.apiBaseURLString = ud.string(forKey: Keys.apiBase) ?? "http://localhost:3000/v1"
        self.useBackend = ud.object(forKey: Keys.useBackend) as? Bool ?? true
    }
}

struct Country: Identifiable, Hashable {
    var id: String { code }
    let code: String
    let name: String
    let flag: String

    static let germany       = Country(code: "DE", name: "Germany",        flag: "🇩🇪")
    static let unitedStates  = Country(code: "US", name: "United States",  flag: "🇺🇸")
    static let unitedKingdom = Country(code: "GB", name: "United Kingdom", flag: "🇬🇧")

    static let supported: [Country] = [.germany, .unitedStates, .unitedKingdom]
}
