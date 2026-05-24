import SwiftUI

struct EventDetailView: View {
    let event: Event
    @Environment(AppEnvironment.self) private var env
    @State private var store = NotificationStore.shared
    @State private var lead: ReminderLead = .oneHour
    @State private var notifyBusy = false

    private var notifyEnabled: Bool { store.isScheduled(eventId: event.id) }

    var sport: Sport { Sport.all.first(where: { $0.slug == event.sportSlug }) ?? Sport.all[0] }

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.l) {
                heroBand
                countdownCard
                    .padding(.horizontal, Theme.Spacing.l)
                broadcastsSection
                    .padding(.horizontal, Theme.Spacing.l)
                notifySection
                    .padding(.horizontal, Theme.Spacing.l)
                if let venue = event.venue {
                    venueRow(venue)
                        .padding(.horizontal, Theme.Spacing.l)
                }
                Color.clear.frame(height: Theme.Spacing.xxl)
            }
        }
        .background(Theme.Color.background.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await store.sync()
            lead = ReminderLead(rawValue: store.leadMinutes(for: event)) ?? .oneHour
        }
    }

    // MARK: - Hero band

    private var heroBand: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            HStack(spacing: Theme.Spacing.s) {
                Image(systemName: sport.symbol)
                    .font(.system(size: 13, weight: .black))
                Text(sport.name.uppercased())
                    .font(.system(size: 11, weight: .heavy))
                    .kerning(1.5)
                if let league = event.league {
                    Text("·")
                        .foregroundStyle(.white.opacity(0.5))
                    Text(league)
                        .font(.system(size: 11, weight: .heavy))
                        .kerning(1.0)
                }
                Spacer()
            }
            .foregroundStyle(.white.opacity(0.9))

            Text(event.title)
                .font(.system(size: 30, weight: .black))
                .kerning(-0.5)
                .foregroundStyle(.white)
                .multilineTextAlignment(.leading)

            if let subtitle = event.subtitle {
                Text(subtitle)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.white.opacity(0.75))
            }
        }
        .padding(.horizontal, Theme.Spacing.xl)
        .padding(.top, Theme.Spacing.xl)
        .padding(.bottom, Theme.Spacing.xxl)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            ZStack {
                Theme.Color.ink
                RadialGradient(
                    colors: [sport.tint.opacity(0.40), .clear],
                    center: .topLeading,
                    startRadius: 20,
                    endRadius: 320
                )
            }
            .ignoresSafeArea(edges: .top)
        )
    }

    // MARK: - Countdown

    private var countdownCard: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            Text("KICKOFF")
                .font(.system(size: 10, weight: .heavy))
                .kerning(1.5)
                .foregroundStyle(Theme.Color.muted)
            Text(fullDate(event.startTimeUTC))
                .font(.system(size: 16, weight: .bold).monospacedDigit())
                .foregroundStyle(Theme.Color.ink)
            TimelineView(.periodic(from: .now, by: 1)) { _ in
                Text(countdownString(to: event.startTimeUTC))
                    .font(.system(size: 44, weight: .black).monospacedDigit())
                    .foregroundStyle(Theme.Color.accent)
                    .kerning(-1)
                    .padding(.top, 2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Theme.Spacing.l)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                .fill(Theme.Color.surface)
        )
        .shadow(color: .black.opacity(0.06), radius: 18, x: 0, y: 6)
        .offset(y: -Theme.Spacing.xl)
        .padding(.bottom, -Theme.Spacing.xl)
    }

    // MARK: - Broadcasts

    private var broadcastsSection: some View {
        let filtered = event.broadcasts.filter { $0.countryCode == env.country.code }
        return VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            HStack {
                Text("WHERE TO WATCH")
                    .font(.system(size: 10, weight: .heavy))
                    .kerning(1.5)
                Text(env.country.flag)
                Spacer()
                Text(env.country.code)
                    .font(.system(size: 10, weight: .heavy))
                    .kerning(1.0)
            }
            .foregroundStyle(Theme.Color.muted)

            if filtered.isEmpty {
                Text("No broadcasters listed for your country yet.")
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.Color.muted)
                    .padding(Theme.Spacing.l)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                            .fill(Theme.Color.surface)
                    )
            } else {
                VStack(spacing: Theme.Spacing.s) {
                    ForEach(filtered, id: \.self) { b in
                        BroadcastRow(broadcast: b, sport: sport)
                    }
                }
            }
        }
    }

    // MARK: - Notify

    private var notifySection: some View {
        VStack(spacing: Theme.Spacing.s) {
            Button {
                Task { await toggleNotify() }
            } label: {
                HStack(spacing: Theme.Spacing.m) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(notifyEnabled ? Theme.Color.accent.opacity(0.15) : Theme.Color.muted.opacity(0.12))
                        Image(systemName: notifyEnabled ? "bell.badge.fill" : "bell.fill")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(notifyEnabled ? Theme.Color.accent : Theme.Color.muted)
                    }
                    .frame(width: 44, height: 44)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(notifyEnabled ? "Reminder set · \(lead.label) before" : "Notify me before kickoff")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Theme.Color.ink)
                        Text(notifyEnabled ? "Tap to cancel" : "Local notification, no account needed")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Theme.Color.muted)
                    }
                    Spacer()
                    Image(systemName: notifyEnabled ? "checkmark.circle.fill" : "plus.circle.fill")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(notifyEnabled ? Theme.Color.accent : Theme.Color.muted.opacity(0.6))
                }
                .padding(Theme.Spacing.m)
                .background(
                    RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                        .fill(Theme.Color.surface)
                )
                .shadow(color: .black.opacity(0.06), radius: 18, x: 0, y: 6)
                .opacity(notifyBusy ? 0.6 : 1)
            }
            .buttonStyle(.plain)
            .disabled(notifyBusy)

            if !notifyEnabled {
                leadChips
            }
        }
    }

    private var leadChips: some View {
        HStack(spacing: Theme.Spacing.s) {
            ForEach(ReminderLead.allCases) { option in
                let selected = lead == option
                Button {
                    lead = option
                    Haptics.selection()
                } label: {
                    Text(option.label)
                        .font(.system(size: 12, weight: .heavy))
                        .kerning(0.5)
                        .padding(.horizontal, Theme.Spacing.m)
                        .padding(.vertical, 8)
                        .foregroundStyle(selected ? .white : Theme.Color.ink)
                        .background(
                            Capsule(style: .continuous)
                                .fill(selected ? Theme.Color.ink : Theme.Color.surface)
                        )
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
        .padding(.horizontal, 2)
    }

    private func venueRow(_ venue: String) -> some View {
        HStack(spacing: Theme.Spacing.m) {
            Image(systemName: "mappin.and.ellipse")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Theme.Color.muted)
                .frame(width: 28)
            Text(venue)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Theme.Color.ink)
            Spacer()
        }
        .padding(Theme.Spacing.m)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                .fill(Theme.Color.surface)
        )
        .shadow(color: .black.opacity(0.06), radius: 18, x: 0, y: 6)
    }

    // MARK: - Actions

    private func toggleNotify() async {
        notifyBusy = true
        defer { notifyBusy = false }
        if notifyEnabled {
            store.cancel(eventId: event.id)
            Haptics.selection()
        } else {
            let ok = await store.schedule(event: event, leadMinutes: lead.rawValue)
            if ok { Haptics.success() } else { Haptics.warning() }
        }
    }

    // MARK: - Helpers

    private func fullDate(_ d: Date) -> String {
        let f = DateFormatter(); f.dateStyle = .full; f.timeStyle = .short
        return f.string(from: d)
    }
    private func countdownString(to date: Date) -> String {
        let s = max(0, Int(date.timeIntervalSinceNow))
        let d = s / 86400, h = (s % 86400) / 3600, m = (s % 3600) / 60, sec = s % 60
        if d > 0 { return String(format: "%dd %02d:%02d:%02d", d, h, m, sec) }
        return String(format: "%02d:%02d:%02d", h, m, sec)
    }
}

private struct BroadcastRow: View {
    let broadcast: Broadcast
    let sport: Sport

    var body: some View {
        HStack(spacing: Theme.Spacing.m) {
            RoundedRectangle(cornerRadius: 2)
                .fill(sport.tint)
                .frame(width: 3, height: 36)
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(sport.tint.opacity(0.12))
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(sport.tint)
            }
            .frame(width: 40, height: 40)
            VStack(alignment: .leading, spacing: 2) {
                Text(broadcast.provider)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Theme.Color.ink)
                Text(label.uppercased())
                    .font(.system(size: 10, weight: .heavy))
                    .kerning(1.2)
                    .foregroundStyle(Theme.Color.muted)
            }
            Spacer()
        }
        .padding(.vertical, Theme.Spacing.s)
        .padding(.horizontal, Theme.Spacing.m)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                .fill(Theme.Color.surface)
        )
        .shadow(color: .black.opacity(0.05), radius: 14, x: 0, y: 4)
    }

    private var icon: String {
        switch broadcast.kind {
        case .tv: return "tv.fill"
        case .stream: return "play.rectangle.fill"
        case .ppv: return "creditcard.fill"
        }
    }
    private var label: String {
        switch broadcast.kind {
        case .tv: return "TV broadcast"
        case .stream: return "Streaming"
        case .ppv: return "Pay-per-view"
        }
    }
}

#Preview {
    NavigationStack {
        EventDetailView(event: MockData.events()[0])
    }
    .environment(AppEnvironment.shared)
}
