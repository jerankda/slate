import SwiftUI

struct SettingsView: View {
    @Environment(AppEnvironment.self) private var env

    var body: some View {
        @Bindable var env = env

        ScrollView {
            VStack(spacing: 0) {
                EditorialHeader(eyebrow: "Preferences", title: "Settings")

                SectionHeader("Country")
                VStack(spacing: Theme.Spacing.s) {
                    ForEach(Country.supported) { c in
                        Button {
                            Haptics.selection()
                            env.country = c
                        } label: {
                            CountryRow(country: c, isSelected: env.country == c)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, Theme.Spacing.l)

                SectionHeader("Notifications")
                VStack(spacing: Theme.Spacing.s) {
                    RemindersCard()
                }
                .padding(.horizontal, Theme.Spacing.l)

                SectionHeader("Data source")
                VStack(spacing: Theme.Spacing.s) {
                    BackendToggleCard(useBackend: $env.useBackend)
                    if env.useBackend {
                        BackendURLCard(urlString: $env.apiBaseURLString)
                    }
                    BackendStatusCard()
                }
                .padding(.horizontal, Theme.Spacing.l)

                SectionHeader("About")
                VStack(spacing: Theme.Spacing.s) {
                    InfoRow(label: "Version", value: appVersion)
                    InfoRow(label: "Made by", value: "brekzware")
                }
                .padding(.horizontal, Theme.Spacing.l)

                Spacer(minLength: Theme.Spacing.xxl)
                BrandFooter()
                    .padding(.top, Theme.Spacing.xxl)
                Color.clear.frame(height: Theme.Spacing.xxl)
            }
        }
        .background(Theme.Color.background.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) { Wordmark(size: 20) }
        }
    }

    private var appVersion: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.1"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(v) (\(b))"
    }
}

private struct CountryRow: View {
    let country: Country
    let isSelected: Bool

    var body: some View {
        HStack(spacing: Theme.Spacing.m) {
            Text(country.flag)
                .font(.system(size: 28))
            VStack(alignment: .leading, spacing: 2) {
                Text(country.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Theme.Color.ink)
                Text(country.code)
                    .font(.system(size: 11, weight: .heavy))
                    .kerning(1.0)
                    .foregroundStyle(Theme.Color.muted)
            }
            Spacer()
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(isSelected ? Theme.Color.accent : Theme.Color.muted.opacity(0.4))
        }
        .padding(Theme.Spacing.m)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                .fill(Theme.Color.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                .strokeBorder(isSelected ? Theme.Color.accent.opacity(0.6) : .clear, lineWidth: 1.5)
        )
        .shadow(color: .black.opacity(0.05), radius: 14, x: 0, y: 4)
    }
}

private struct InfoCard: View {
    let symbol: String
    let title: String
    let message: String

    var body: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.m) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Theme.Color.accent.opacity(0.14))
                Image(systemName: symbol)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Theme.Color.accent)
            }
            .frame(width: 40, height: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Theme.Color.ink)
                Text(message)
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.Color.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
        .padding(Theme.Spacing.m)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                .fill(Theme.Color.surface)
        )
        .shadow(color: .black.opacity(0.05), radius: 14, x: 0, y: 4)
    }
}

private struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Theme.Color.muted)
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .semibold).monospacedDigit())
                .foregroundStyle(Theme.Color.ink)
        }
        .padding(.horizontal, Theme.Spacing.m)
        .padding(.vertical, Theme.Spacing.m)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                .fill(Theme.Color.surface)
        )
        .shadow(color: .black.opacity(0.05), radius: 14, x: 0, y: 4)
    }
}

private struct BrandFooter: View {
    var body: some View {
        VStack(spacing: Theme.Spacing.s) {
            Wordmark(size: 22)
            Text("Know what's on. Know where to watch.")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Theme.Color.muted)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    NavigationStack { SettingsView() }
        .environment(AppEnvironment.shared)
}

// MARK: - Backend cards

private struct BackendToggleCard: View {
    @Binding var useBackend: Bool

    var body: some View {
        HStack(spacing: Theme.Spacing.m) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Theme.Color.accent.opacity(0.14))
                Image(systemName: "server.rack")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Theme.Color.accent)
            }
            .frame(width: 40, height: 40)

            VStack(alignment: .leading, spacing: 2) {
                Text("Use backend")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Theme.Color.ink)
                Text(useBackend ? "Live data from slate. API" : "Bundled demo schedule")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.Color.muted)
            }
            Spacer()
            Toggle("", isOn: $useBackend)
                .labelsHidden()
                .tint(Theme.Color.accent)
        }
        .padding(Theme.Spacing.m)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                .fill(Theme.Color.surface)
        )
        .shadow(color: .black.opacity(0.05), radius: 14, x: 0, y: 4)
    }
}

private struct BackendURLCard: View {
    @Binding var urlString: String

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            Text("API base URL")
                .font(.system(size: 11, weight: .heavy))
                .kerning(1.0)
                .foregroundStyle(Theme.Color.muted)
            TextField("http://localhost:3000/v1", text: $urlString)
                .font(.system(size: 14, weight: .medium).monospaced())
                .foregroundStyle(Theme.Color.ink)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .keyboardType(.URL)
                .padding(.vertical, 10)
                .padding(.horizontal, Theme.Spacing.m)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Theme.Color.background)
                )
        }
        .padding(Theme.Spacing.m)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                .fill(Theme.Color.surface)
        )
        .shadow(color: .black.opacity(0.05), radius: 14, x: 0, y: 4)
    }
}

private struct BackendStatusCard: View {
    @State private var source: EventRepository.Source = .mock
    @State private var error: String?
    @State private var savedAt: Date?

    private var statusColor: Color {
        switch source {
        case .backend: return Theme.Color.accent
        case .cache:   return Theme.Color.live
        case .mock:    return Theme.Color.muted
        }
    }

    private var statusTitle: String {
        switch source {
        case .backend: return "Connected to backend"
        case .cache:   return "Offline — using cached data"
        case .mock:    return "Using demo data"
        }
    }

    var body: some View {
        HStack(spacing: Theme.Spacing.m) {
            Circle().fill(statusColor).frame(width: 8, height: 8)
            VStack(alignment: .leading, spacing: 2) {
                Text(statusTitle)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.Color.ink)
                if let savedAt {
                    Text("Last updated \(savedAt.formatted(.relative(presentation: .named)))")
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.Color.muted)
                } else if let error {
                    Text(error)
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.Color.muted)
                }
            }
            Spacer()
        }
        .padding(Theme.Spacing.m)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                .fill(Theme.Color.surface)
        )
        .shadow(color: .black.opacity(0.05), radius: 14, x: 0, y: 4)
        .task {
            source = EventRepository.shared.lastSource
            error = EventRepository.shared.lastError
            savedAt = EventRepository.shared.lastSavedAt
        }
    }
}

// MARK: - Reminders

private struct RemindersCard: View {
    @State private var store = NotificationStore.shared
    @State private var showingConfirm = false

    private var statusText: String {
        switch store.authorizationStatus {
        case .authorized, .provisional, .ephemeral: return "Notifications enabled"
        case .denied: return "Notifications disabled in iOS Settings"
        case .notDetermined: return "Tap an event to enable reminders"
        @unknown default: return "Unknown status"
        }
    }

    private var statusColor: Color {
        switch store.authorizationStatus {
        case .authorized, .provisional, .ephemeral: return Theme.Color.accent
        case .denied: return Theme.Color.live
        default: return Theme.Color.muted
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            HStack(spacing: Theme.Spacing.m) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(statusColor.opacity(0.15))
                    Image(systemName: "bell.badge.fill")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(statusColor)
                }
                .frame(width: 44, height: 44)

                VStack(alignment: .leading, spacing: 2) {
                    Text("\(store.scheduledEventIds.count) active reminder\(store.scheduledEventIds.count == 1 ? "" : "s")")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Theme.Color.ink)
                    Text(statusText)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Theme.Color.muted)
                }
                Spacer()
            }

            if store.authorizationStatus == .denied {
                Button {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    Text("Open iOS Settings")
                        .font(.system(size: 13, weight: .heavy))
                        .kerning(0.5)
                        .foregroundStyle(.white)
                        .padding(.horizontal, Theme.Spacing.l)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                        .background(Capsule(style: .continuous).fill(Theme.Color.ink))
                }
                .buttonStyle(.plain)
            }

            if !store.scheduledEventIds.isEmpty {
                Button(role: .destructive) {
                    showingConfirm = true
                } label: {
                    Text("Clear all reminders")
                        .font(.system(size: 13, weight: .heavy))
                        .kerning(0.5)
                        .foregroundStyle(Theme.Color.live)
                        .padding(.horizontal, Theme.Spacing.l)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                        .background(
                            Capsule(style: .continuous)
                                .stroke(Theme.Color.live.opacity(0.4), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                .confirmationDialog(
                    "Clear all reminders?",
                    isPresented: $showingConfirm,
                    titleVisibility: .visible
                ) {
                    Button("Clear all", role: .destructive) {
                        store.clearAll()
                        Haptics.warning()
                    }
                    Button("Cancel", role: .cancel) {}
                }
            }
        }
        .padding(Theme.Spacing.m)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                .fill(Theme.Color.surface)
        )
        .shadow(color: .black.opacity(0.05), radius: 14, x: 0, y: 4)
        .task { await store.sync() }
    }
}
