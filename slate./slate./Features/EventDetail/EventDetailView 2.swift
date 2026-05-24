import SwiftUI

struct EventDetailView: View {
    let event: Event
    @Environment(AppEnvironment.self) private var env
    @State private var notifyEnabled = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.l) {
                header
                countdownCard
                broadcastsSection
                notifySection
            }
            .padding(Theme.Spacing.l)
        }
        .background(Theme.Color.background)
        .navigationTitle(event.league ?? "Event")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            Text(event.title)
                .font(Theme.Font.display(28, weight: .black))
                .foregroundStyle(Theme.Color.ink)
            if let subtitle = event.subtitle {
                Text(subtitle)
                    .font(Theme.Font.body(15, weight: .medium))
                    .foregroundStyle(Theme.Color.muted)
            }
            if let venue = event.venue {
                Label(venue, systemImage: "mappin.and.ellipse")
                    .font(Theme.Font.body(13, weight: .medium))
                    .foregroundStyle(Theme.Color.muted)
            }
        }
    }

    private var countdownCard: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text("KICKOFF")
                .font(Theme.Font.body(11, weight: .heavy))
                .foregroundStyle(Theme.Color.muted)
            Text(fullDateString(event.startTimeUTC))
                .font(Theme.Font.mono(20, weight: .bold))
                .foregroundStyle(Theme.Color.ink)
            TimelineView(.periodic(from: .now, by: 1)) { _ in
                Text(countdownString(to: event.startTimeUTC))
                    .font(Theme.Font.mono(34, weight: .black))
                    .foregroundStyle(Theme.Color.accent)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Theme.Spacing.l)
        .cardStyle()
    }

    private var broadcastsSection: some View {
        let filtered = event.broadcasts.filter { $0.countryCode == env.country.code }
        return VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            Text("WHERE TO WATCH (\(env.country.flag) \(env.country.code))")
                .font(Theme.Font.body(11, weight: .heavy))
                .foregroundStyle(Theme.Color.muted)
            if filtered.isEmpty {
                Text("No broadcasters listed for your country yet.")
                    .font(Theme.Font.body(14))
                    .foregroundStyle(Theme.Color.muted)
            } else {
                ForEach(filtered, id: \.self) { b in
                    HStack {
                        Image(systemName: icon(for: b.kind))
                            .foregroundStyle(Theme.Color.accent)
                        Text(b.provider)
                            .font(Theme.Font.body(15, weight: .semibold))
                            .foregroundStyle(Theme.Color.ink)
                        Spacer()
                        Text(b.kind.rawValue.uppercased())
                            .font(Theme.Font.body(11, weight: .heavy))
                            .foregroundStyle(Theme.Color.muted)
                    }
                    .padding(Theme.Spacing.m)
                    .cardStyle()
                }
            }
        }
    }

    private var notifySection: some View {
        Toggle(isOn: $notifyEnabled) {
            Label("Notify me 1 hour before", systemImage: "bell.fill")
                .font(Theme.Font.body(15, weight: .semibold))
        }
        .tint(Theme.Color.accent)
        .padding(Theme.Spacing.l)
        .cardStyle()
        .onChange(of: notifyEnabled) { _, new in
            if new { Haptics.success() } else { Haptics.selection() }
        }
    }

    private func icon(for kind: Broadcast.Kind) -> String {
        switch kind {
        case .tv: return "tv.fill"
        case .stream: return "play.rectangle.fill"
        case .ppv: return "creditcard.fill"
        }
    }

    private func fullDateString(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .full
        f.timeStyle = .short
        return f.string(from: date)
    }

    private func countdownString(to date: Date) -> String {
        let interval = max(0, Int(date.timeIntervalSinceNow))
        let d = interval / 86400
        let h = (interval % 86400) / 3600
        let m = (interval % 3600) / 60
        let s = interval % 60
        if d > 0 { return String(format: "%dd %02d:%02d:%02d", d, h, m, s) }
        return String(format: "%02d:%02d:%02d", h, m, s)
    }
}

struct EmptyStateView: View {
    let symbol: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: Theme.Spacing.m) {
            Image(systemName: symbol)
                .font(.system(size: 44, weight: .regular))
                .foregroundStyle(Theme.Color.muted)
            Text(title)
                .font(Theme.Font.display(20, weight: .bold))
                .foregroundStyle(Theme.Color.ink)
            Text(message)
                .font(Theme.Font.body(14))
                .foregroundStyle(Theme.Color.muted)
                .multilineTextAlignment(.center)
        }
        .padding(Theme.Spacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.Color.background)
    }
}

#Preview {
    NavigationStack {
        EventDetailView(event: MockData.events()[0])
    }
    .environment(AppEnvironment.shared)
}
