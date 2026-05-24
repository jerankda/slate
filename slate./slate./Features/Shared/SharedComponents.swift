import SwiftUI

struct EventRow: View {
    let event: Event
    @State private var store = NotificationStore.shared
    var sport: Sport { Sport.all.first(where: { $0.slug == event.sportSlug }) ?? Sport.all[0] }

    var body: some View {
        HStack(spacing: Theme.Spacing.m) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(sport.tint.opacity(0.14))
                Image(systemName: sport.symbol)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(sport.tint)
            }
            .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    if let league = event.league {
                        Text(league.uppercased())
                            .font(.system(size: 10, weight: .heavy))
                            .kerning(0.8)
                            .foregroundStyle(Theme.Color.muted)
                    }
                    if event.isLive { LivePill() }
                    if store.isScheduled(eventId: event.id) {
                        Image(systemName: "bell.fill")
                            .font(.system(size: 9, weight: .black))
                            .foregroundStyle(Theme.Color.accent)
                            .accessibilityLabel("Reminder set")
                    }
                }
                Text(event.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Theme.Color.ink)
                    .lineLimit(2)
            }

            Spacer(minLength: Theme.Spacing.s)

            VStack(alignment: .trailing, spacing: 2) {
                Text(timeOfDay(event.startTimeUTC))
                    .font(.system(size: 15, weight: .heavy).monospacedDigit())
                    .foregroundStyle(Theme.Color.ink)
                Text(relative(event.startTimeUTC))
                    .font(.system(size: 11, weight: .semibold).monospacedDigit())
                    .foregroundStyle(Theme.Color.muted)
            }
        }
        .padding(.vertical, Theme.Spacing.m)
        .padding(.horizontal, Theme.Spacing.l)
        .background(Theme.Color.background)
        .contentShape(Rectangle())
    }

    private func timeOfDay(_ d: Date) -> String {
        let f = DateFormatter(); f.timeStyle = .short; return f.string(from: d)
    }
    private func relative(_ d: Date) -> String {
        let s = Int(d.timeIntervalSinceNow)
        if s < 0 { return "started" }
        let h = s / 3600, m = (s % 3600) / 60
        if h >= 48 { return "in \(h/24)d" }
        if h >= 1 { return "in \(h)h \(m)m" }
        return "in \(m)m"
    }
}

struct EmptyStateView: View {
    let symbol: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: Theme.Spacing.m) {
            Image(systemName: symbol)
                .font(.system(size: 40, weight: .regular))
                .foregroundStyle(Theme.Color.muted.opacity(0.6))
            Text(title)
                .font(.system(size: 18, weight: .black))
                .foregroundStyle(Theme.Color.ink)
            Text(message)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Theme.Color.muted)
                .multilineTextAlignment(.center)
        }
        .padding(Theme.Spacing.xl)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - LIVE pill (used by EventRow + hero card)

struct LivePill: View {
    var body: some View {
        TimelineView(.periodic(from: .now, by: 1.0)) { ctx in
            HStack(spacing: 4) {
                Circle()
                    .fill(.white)
                    .frame(width: 5, height: 5)
                    .opacity(Int(ctx.date.timeIntervalSince1970) % 2 == 0 ? 1.0 : 0.35)
                Text("LIVE")
                    .font(.system(size: 9, weight: .heavy))
                    .kerning(1.0)
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(Capsule(style: .continuous).fill(Theme.Color.live))
        }
    }
}

// MARK: - Skeleton row (loading state)

struct EventRowSkeleton: View {
    @State private var phase: CGFloat = 0

    var body: some View {
        HStack(spacing: Theme.Spacing.m) {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Theme.Color.surface)
                .frame(width: 44, height: 44)
            VStack(alignment: .leading, spacing: 6) {
                RoundedRectangle(cornerRadius: 4).fill(Theme.Color.surface).frame(width: 60, height: 8)
                RoundedRectangle(cornerRadius: 4).fill(Theme.Color.surface).frame(maxWidth: .infinity).frame(height: 14)
            }
            Spacer(minLength: Theme.Spacing.s)
            RoundedRectangle(cornerRadius: 4).fill(Theme.Color.surface).frame(width: 50, height: 14)
        }
        .padding(.vertical, Theme.Spacing.m)
        .padding(.horizontal, Theme.Spacing.l)
        .overlay(
            // shimmer
            GeometryReader { g in
                LinearGradient(
                    colors: [.clear, .white.opacity(0.35), .clear],
                    startPoint: .leading, endPoint: .trailing
                )
                .frame(width: g.size.width * 0.4)
                .offset(x: -g.size.width * 0.4 + (g.size.width * 1.4) * phase)
                .blendMode(.plusLighter)
            }
            .allowsHitTesting(false)
            .mask(Rectangle())
        )
        .onAppear {
            withAnimation(.linear(duration: 1.4).repeatForever(autoreverses: false)) {
                phase = 1.0
            }
        }
    }
}
