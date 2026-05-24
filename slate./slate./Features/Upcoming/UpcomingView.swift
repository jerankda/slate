import SwiftUI

struct UpcomingView: View {
    @Environment(AppEnvironment.self) private var env
    @State private var filter: String? = nil
    @State private var raw: [Event] = []
    @State private var isLoading = false
    @State private var didLoadOnce = false

    var body: some View {
        let all = raw
            .filter { filter == nil || $0.sportSlug == filter }
            .sorted { $0.startTimeUTC < $1.startTimeUTC }
        let grouped = group(all)

        ScrollView {
            VStack(spacing: 0) {
                EditorialHeader(
                    eyebrow: "\(env.country.flag)  \(all.count) events · next 14 days",
                    title: "Upcoming"
                )

                if let hero = all.first {
                    NavigationLink(value: hero) {
                        HeroEventCard(event: hero)
                            .padding(.horizontal, Theme.Spacing.l)
                            .padding(.top, Theme.Spacing.s)
                    }
                    .buttonStyle(.plain)
                    .simultaneousGesture(TapGesture().onEnded { Haptics.rigid() })
                }

                FilterChips(selection: $filter)
                    .padding(.top, Theme.Spacing.l)

                if all.count <= 1 {
                    if all.isEmpty {
                        if isLoading && !didLoadOnce {
                            VStack(spacing: 0) {
                                ForEach(0..<6, id: \.self) { _ in EventRowSkeleton() }
                            }
                            .padding(.top, Theme.Spacing.l)
                        } else {
                            EmptyStateView(
                                symbol: "calendar.badge.exclamationmark",
                                title: "Nothing scheduled",
                                message: "Try a different sport or pull to refresh."
                            )
                            .padding(.top, Theme.Spacing.xxl)
                        }
                    }
                } else {
                    LazyVStack(spacing: 0, pinnedViews: []) {
                        ForEach(grouped, id: \.title) { section in
                            if section.events.contains(where: { $0.id != all.first?.id }) {
                                SectionHeader(section.title, trailing: "\(section.events.filter { $0.id != all.first?.id }.count)")
                                ForEach(section.events.filter { $0.id != all.first?.id }) { event in
                                    NavigationLink(value: event) {
                                        EventRow(event: event)
                                    }
                                    .buttonStyle(.plain)
                                    .simultaneousGesture(TapGesture().onEnded { Haptics.soft() })
                                    Rectangle()
                                        .fill(Theme.Color.hairline)
                                        .frame(height: 1)
                                        .padding(.leading, Theme.Spacing.l + 44 + Theme.Spacing.m)
                                }
                            }
                        }
                    }
                    .padding(.top, Theme.Spacing.s)
                }

                Color.clear.frame(height: Theme.Spacing.xxl)
            }
        }
        .background(Theme.Color.background.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) { Wordmark(size: 20) }
        }
        .navigationDestination(for: Event.self) { EventDetailView(event: $0) }
        .task(id: env.country.code) { await load() }
        .refreshable { await load() }
    }

    private func load() async {
        // First, paint instantly from disk cache so the app never shows a blank screen on launch.
        if !didLoadOnce {
            let cached = EventRepository.shared.cached(country: env.country.code)
            if !cached.isEmpty { raw = cached }
        }
        isLoading = true
        let fresh = await EventRepository.shared.events(country: env.country.code)
        if !fresh.isEmpty { raw = fresh }
        isLoading = false
        didLoadOnce = true
    }

    // MARK: - Grouping

    private struct DaySection { let title: String; let events: [Event] }

    private func group(_ events: [Event]) -> [DaySection] {
        let cal = Calendar.current
        let now = Date()
        var today: [Event] = []
        var tomorrow: [Event] = []
        var thisWeek: [Event] = []
        var later: [Event] = []

        for e in events {
            if cal.isDateInToday(e.startTimeUTC) { today.append(e) }
            else if cal.isDateInTomorrow(e.startTimeUTC) { tomorrow.append(e) }
            else if let days = cal.dateComponents([.day], from: now, to: e.startTimeUTC).day, days <= 7 { thisWeek.append(e) }
            else { later.append(e) }
        }

        var sections: [DaySection] = []
        if !today.isEmpty    { sections.append(.init(title: "Today",    events: today)) }
        if !tomorrow.isEmpty { sections.append(.init(title: "Tomorrow", events: tomorrow)) }
        if !thisWeek.isEmpty { sections.append(.init(title: "This Week", events: thisWeek)) }
        if !later.isEmpty    { sections.append(.init(title: "Later",    events: later)) }
        return sections
    }
}

// MARK: - Hero card

private struct HeroEventCard: View {
    let event: Event
    var sport: Sport { Sport.all.first(where: { $0.slug == event.sportSlug }) ?? Sport.all[0] }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.l) {
            HStack(spacing: Theme.Spacing.s) {
                Image(systemName: sport.symbol)
                    .font(.system(size: 12, weight: .black))
                Text((event.isLive ? "Live now · \(sport.name)" : "Up Next · \(sport.name)").uppercased())
                    .font(.system(size: 11, weight: .heavy))
                    .kerning(1.2)
                Spacer()
                if event.isLive { LivePill() }
            }
            .foregroundStyle(.white.opacity(0.85))

            Text(event.title)
                .font(.system(size: 26, weight: .black))
                .kerning(-0.3)
                .foregroundStyle(.white)
                .lineLimit(3)
                .multilineTextAlignment(.leading)

            if let subtitle = event.subtitle {
                Text(subtitle)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white.opacity(0.75))
            }

            TimelineView(.periodic(from: .now, by: 1)) { _ in
                HStack(alignment: .firstTextBaseline, spacing: Theme.Spacing.m) {
                    Text(countdown(to: event.startTimeUTC))
                        .font(.system(size: 38, weight: .black).monospacedDigit())
                        .foregroundStyle(.white)
                        .kerning(-0.5)
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(kickoff(event.startTimeUTC))
                            .font(.system(size: 13, weight: .heavy).monospacedDigit())
                            .foregroundStyle(.white)
                        Text("KICKOFF")
                            .font(.system(size: 9, weight: .heavy))
                            .kerning(1.2)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
            }
        }
        .padding(Theme.Spacing.xl)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Theme.Color.ink)
                .overlay(
                    // subtle accent glow corner — kept inside the card (not chrome)
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(
                            RadialGradient(
                                colors: [Theme.Color.accent.opacity(0.35), .clear],
                                center: .topTrailing,
                                startRadius: 10,
                                endRadius: 260
                            )
                        )
                )
        )
        .shadow(color: .black.opacity(0.18), radius: 30, x: 0, y: 14)
    }

    private func kickoff(_ d: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "EEE · HH:mm"
        return f.string(from: d)
    }
    private func countdown(to date: Date) -> String {
        let s = max(0, Int(date.timeIntervalSinceNow))
        let d = s / 86400, h = (s % 86400) / 3600, m = (s % 3600) / 60, sec = s % 60
        if d > 0 { return String(format: "%dd %02d:%02d:%02d", d, h, m, sec) }
        return String(format: "%02d:%02d:%02d", h, m, sec)
    }
}

// MARK: - Filter chips

private struct FilterChips: View {
    @Binding var selection: String?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.Spacing.s) {
                Chip(label: "All", systemImage: "circle.grid.2x2.fill", isSelected: selection == nil) {
                    Haptics.selection(); selection = nil
                }
                ForEach(Sport.all) { sport in
                    Chip(label: sport.name, systemImage: sport.symbol, isSelected: selection == sport.slug) {
                        Haptics.selection(); selection = sport.slug
                    }
                }
            }
            .padding(.horizontal, Theme.Spacing.l)
        }
    }
}

private struct Chip: View {
    let label: String
    let systemImage: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: systemImage)
                    .font(.system(size: 11, weight: .bold))
                Text(label)
                    .font(.system(size: 13, weight: .semibold))
            }
            .padding(.horizontal, Theme.Spacing.m)
            .padding(.vertical, 8)
            .foregroundStyle(isSelected ? .white : Theme.Color.ink)
            .background(
                Capsule(style: .continuous)
                    .fill(isSelected ? Theme.Color.ink : Theme.Color.surface)
            )
            .overlay(
                Capsule(style: .continuous)
                    .strokeBorder(Theme.Color.hairline, lineWidth: isSelected ? 0 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack { UpcomingView() }
        .environment(AppEnvironment.shared)
}
