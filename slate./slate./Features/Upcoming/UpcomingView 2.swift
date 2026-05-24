import SwiftUI

struct UpcomingView: View {
    @Environment(AppEnvironment.self) private var env
    @State private var filter: String? = nil

    var body: some View {
        let events = MockData.events(for: env.country.code)
            .filter { filter == nil || $0.sportSlug == filter }
            .sorted { $0.startTimeUTC < $1.startTimeUTC }

        VStack(spacing: 0) {
            FilterChips(selection: $filter)
                .padding(.horizontal, Theme.Spacing.l)
                .padding(.vertical, Theme.Spacing.s)

            if events.isEmpty {
                EmptyStateView(
                    symbol: "calendar.badge.exclamationmark",
                    title: "Nothing scheduled",
                    message: "Try a different sport or check back soon."
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
            }
        }
        .background(Theme.Color.background)
        .navigationTitle("Upcoming")
        .navigationDestination(for: Event.self) { EventDetailView(event: $0) }
    }
}

private struct FilterChips: View {
    @Binding var selection: String?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.Spacing.s) {
                Chip(label: "All", isSelected: selection == nil) {
                    Haptics.selection()
                    selection = nil
                }
                ForEach(Sport.all) { sport in
                    Chip(label: sport.name, isSelected: selection == sport.slug) {
                        Haptics.selection()
                        selection = sport.slug
                    }
                }
            }
        }
    }
}

private struct Chip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(Theme.Font.body(14, weight: .semibold))
                .padding(.horizontal, Theme.Spacing.m)
                .padding(.vertical, Theme.Spacing.s)
                .foregroundStyle(isSelected ? Color.white : Theme.Color.ink)
                .background(
                    Capsule(style: .continuous)
                        .fill(isSelected ? Theme.Color.accent : Theme.Color.surface)
                )
        }
        .buttonStyle(.plain)
    }
}

struct EventRow: View {
    let event: Event

    var body: some View {
        HStack(alignment: .center, spacing: Theme.Spacing.m) {
            VStack(alignment: .leading, spacing: 2) {
                Text(relativeTime(event.startTimeUTC))
                    .font(Theme.Font.mono(13, weight: .bold))
                    .foregroundStyle(Theme.Color.muted)
                Text(event.title)
                    .font(Theme.Font.body(16, weight: .semibold))
                    .foregroundStyle(Theme.Color.ink)
                    .lineLimit(2)
                if let league = event.league {
                    Text(league)
                        .font(Theme.Font.body(12, weight: .medium))
                        .foregroundStyle(Theme.Color.muted)
                }
            }
            Spacer(minLength: 0)
            Text(timeOfDay(event.startTimeUTC))
                .font(Theme.Font.mono(16, weight: .heavy))
                .foregroundStyle(Theme.Color.ink)
        }
        .padding(.vertical, Theme.Spacing.s)
    }

    private func timeOfDay(_ date: Date) -> String {
        let f = DateFormatter()
        f.timeStyle = .short
        return f.string(from: date)
    }

    private func relativeTime(_ date: Date) -> String {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .abbreviated
        return f.localizedString(for: date, relativeTo: .now).uppercased()
    }
}

#Preview {
    NavigationStack { UpcomingView() }
        .environment(AppEnvironment.shared)
}
