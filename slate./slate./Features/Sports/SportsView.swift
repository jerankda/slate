import SwiftUI

struct SportsView: View {
    @Environment(AppEnvironment.self) private var env
    @State private var allEvents: [Event] = []

    private let columns = [
        GridItem(.flexible(), spacing: Theme.Spacing.m),
        GridItem(.flexible(), spacing: Theme.Spacing.m),
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                EditorialHeader(
                    eyebrow: "\(env.country.flag)  \(env.country.name)",
                    title: "Sports"
                )

                LazyVGrid(columns: columns, spacing: Theme.Spacing.m) {
                    ForEach(Sport.all) { sport in
                        let count = allEvents.filter { $0.sportSlug == sport.slug }.count
                        NavigationLink(value: sport) {
                            SportCard(sport: sport, eventCount: count)
                        }
                        .buttonStyle(.plain)
                        .simultaneousGesture(TapGesture().onEnded { Haptics.rigid() })
                    }
                }
                .padding(.horizontal, Theme.Spacing.l)
                .padding(.top, Theme.Spacing.s)

                Color.clear.frame(height: Theme.Spacing.xxl)
            }
        }
        .background(Theme.Color.background.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) { Wordmark(size: 20) }
        }
        .navigationDestination(for: Sport.self) { sport in
            EventsListView(sport: sport)
        }
        .navigationDestination(for: Event.self) { EventDetailView(event: $0) }
        .task(id: env.country.code) {
            allEvents = await EventRepository.shared.events(country: env.country.code)
        }
        .refreshable {
            allEvents = await EventRepository.shared.events(country: env.country.code)
        }
    }
}

private struct SportCard: View {
    let sport: Sport
    let eventCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Accent leading stripe + icon
            HStack(alignment: .top) {
                Image(systemName: sport.symbol)
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(sport.tint)
                Spacer()
                Text("\(eventCount)")
                    .font(.system(size: 28, weight: .black).monospacedDigit())
                    .foregroundStyle(Theme.Color.ink)
                    .kerning(-0.5)
            }
            Spacer(minLength: Theme.Spacing.l)
            VStack(alignment: .leading, spacing: 2) {
                Text(sport.name)
                    .font(.system(size: 18, weight: .black))
                    .foregroundStyle(Theme.Color.ink)
                Text(eventCount == 1 ? "1 event" : "\(eventCount) events")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.Color.muted)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 150, alignment: .topLeading)
        .padding(Theme.Spacing.l)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                .fill(Theme.Color.surface)
        )
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 2)
                .fill(sport.tint)
                .frame(width: 3)
                .padding(.vertical, Theme.Spacing.l)
        }
        .shadow(color: .black.opacity(0.06), radius: 18, x: 0, y: 6)
    }
}

struct EventsListView: View {
    let sport: Sport
    @Environment(AppEnvironment.self) private var env
    @State private var events: [Event] = []

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                EditorialHeader(
                    eyebrow: "\(events.count) upcoming · next 14 days",
                    title: sport.name
                )

                if events.isEmpty {
                    EmptyStateView(
                        symbol: sport.symbol,
                        title: "No \(sport.name) events",
                        message: "We'll let you know as soon as the schedule drops."
                    )
                    .padding(.top, Theme.Spacing.xxl)
                } else {
                    LazyVStack(spacing: 0) {
                        ForEach(events) { event in
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
                    .padding(.top, Theme.Spacing.s)
                }
                Color.clear.frame(height: Theme.Spacing.xxl)
            }
        }
        .background(Theme.Color.background.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .task(id: env.country.code) {
            events = await EventRepository.shared.events(sportSlug: sport.slug, country: env.country.code)
        }
        .refreshable {
            events = await EventRepository.shared.events(sportSlug: sport.slug, country: env.country.code)
        }
    }
}

#Preview {
    NavigationStack { SportsView() }
        .environment(AppEnvironment.shared)
}
