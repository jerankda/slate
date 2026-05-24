import SwiftUI

/// Lists all events the user has set local reminders for, with the ability to cancel them.
/// Presented as a sheet from the Settings reminders card.
struct RemindersListView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppEnvironment.self) private var env
    @State private var store = NotificationStore.shared
    @State private var allEvents: [Event] = []
    @State private var isLoading = false

    private var reminders: [Event] {
        let ids = store.scheduledEventIds
        return allEvents
            .filter { ids.contains($0.id) }
            .sorted { $0.startTimeUTC < $1.startTimeUTC }
    }

    var body: some View {
        NavigationStack {
            Group {
                if reminders.isEmpty {
                    EmptyStateView(
                        symbol: "bell.slash",
                        title: "No reminders yet",
                        message: "Open any event and tap “Notify me before kickoff” to set one."
                    )
                } else {
                    ScrollView {
                        VStack(spacing: Theme.Spacing.s) {
                            ForEach(reminders) { event in
                                ReminderRow(event: event) {
                                    store.cancel(eventId: event.id)
                                    Haptics.selection()
                                }
                            }
                        }
                        .padding(.horizontal, Theme.Spacing.l)
                        .padding(.top, Theme.Spacing.l)
                        .padding(.bottom, Theme.Spacing.xxl)
                    }
                }
            }
            .background(Theme.Color.background.ignoresSafeArea())
            .navigationTitle("Reminders")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Theme.Color.ink)
                }
            }
            .task { await load() }
        }
    }

    private func load() async {
        isLoading = true
        defer { isLoading = false }
        await store.sync()
        allEvents = await EventRepository.shared.events(country: env.country.code)
    }
}

private struct ReminderRow: View {
    let event: Event
    let onCancel: () -> Void

    var sport: Sport { Sport.all.first(where: { $0.slug == event.sportSlug }) ?? Sport.all[0] }

    var body: some View {
        HStack(spacing: Theme.Spacing.m) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(sport.tint.opacity(0.14))
                Image(systemName: sport.symbol)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(sport.tint)
            }
            .frame(width: 40, height: 40)

            VStack(alignment: .leading, spacing: 2) {
                Text(event.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.Color.ink)
                    .lineLimit(2)
                Text(when(event.startTimeUTC))
                    .font(.system(size: 11, weight: .medium).monospacedDigit())
                    .foregroundStyle(Theme.Color.muted)
            }

            Spacer(minLength: Theme.Spacing.s)

            Button(action: onCancel) {
                Image(systemName: "bell.slash.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Theme.Color.live)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(Theme.Color.live.opacity(0.12)))
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, Theme.Spacing.s)
        .padding(.horizontal, Theme.Spacing.m)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                .fill(Theme.Color.surface)
        )
        .shadow(color: .black.opacity(0.05), radius: 14, x: 0, y: 4)
    }

    private func when(_ d: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "EEE d MMM · HH:mm"
        return f.string(from: d)
    }
}

#Preview {
    RemindersListView()
        .environment(AppEnvironment.shared)
}
