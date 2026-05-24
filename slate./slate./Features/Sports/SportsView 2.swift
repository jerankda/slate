import SwiftUI

struct SportsView: View {
    private let columns = [
        GridItem(.flexible(), spacing: Theme.Spacing.l),
        GridItem(.flexible(), spacing: Theme.Spacing.l),
    ]
    private let sports = Sport.all

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: Theme.Spacing.l) {
                ForEach(sports) { sport in
                    NavigationLink(value: sport) {
                        SportCard(sport: sport)
                    }
                    .buttonStyle(.plain)
                    .simultaneousGesture(TapGesture().onEnded { Haptics.rigid() })
                }
            }
            .padding(Theme.Spacing.l)
        }
        .background(Theme.Color.background)
        .navigationTitle("slate.")
        .navigationDestination(for: Sport.self) { sport in
            EventsListView(sport: sport)
        }
    }
}

private struct SportCard: View {
    let sport: Sport

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            Image(systemName: sport.symbol)
                .font(.system(size: 32, weight: .bold))
                .foregroundStyle(Theme.Color.accent)
            Text(sport.name)
                .font(Theme.Font.display(22, weight: .black))
                .foregroundStyle(Theme.Color.ink)
        }
        .frame(maxWidth: .infinity, minHeight: 140, alignment: .topLeading)
        .padding(Theme.Spacing.l)
        .cardStyle()
    }
}

struct EventsListView: View {
    let sport: Sport
    @Environment(AppEnvironment.self) private var env

    var body: some View {
        let events = MockData.events(for: env.country.code)
            .filter { $0.sportSlug == sport.slug }
            .sorted { $0.startTimeUTC < $1.startTimeUTC }

        Group {
            if events.isEmpty {
                EmptyStateView(
                    symbol: sport.symbol,
                    title: "No \(sport.name) events",
                    message: "We'll let you know as soon as the schedule drops."
                )
            } else {
                List(events) { event in
                    NavigationLink(value: event) {
                        EventRow(event: event)
                    }
                    .listRowBackground(Theme.Color.background)
                    .listRowSeparatorTint(Theme.Color.hairline)
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .background(Theme.Color.background)
            }
        }
        .navigationTitle(sport.name)
        .navigationDestination(for: Event.self) { EventDetailView(event: $0) }
    }
}

#Preview {
    NavigationStack { SportsView() }
        .environment(AppEnvironment.shared)
}
