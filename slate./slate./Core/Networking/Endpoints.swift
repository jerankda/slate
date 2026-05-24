import Foundation

struct Endpoint {
    let url: URL

    static func sports(base: URL) -> Endpoint {
        Endpoint(url: base.appending(path: "sports"))
    }

    static func events(base: URL, sportSlug: String, country: String, from: Date, to: Date) -> Endpoint {
        var comps = URLComponents(url: base.appending(path: "sports/\(sportSlug)/events"), resolvingAgainstBaseURL: false)!
        let iso = ISO8601DateFormatter()
        comps.queryItems = [
            .init(name: "country", value: country),
            .init(name: "from", value: iso.string(from: from)),
            .init(name: "to", value: iso.string(from: to)),
        ]
        return Endpoint(url: comps.url!)
    }

    static func event(base: URL, id: String, country: String) -> Endpoint {
        var comps = URLComponents(url: base.appending(path: "events/\(id)"), resolvingAgainstBaseURL: false)!
        comps.queryItems = [.init(name: "country", value: country)]
        return Endpoint(url: comps.url!)
    }
}
