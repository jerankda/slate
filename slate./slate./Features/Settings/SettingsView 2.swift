import SwiftUI

struct SettingsView: View {
    @Environment(AppEnvironment.self) private var env

    var body: some View {
        @Bindable var env = env
        List {
            Section("Country") {
                Picker("Country", selection: $env.country) {
                    ForEach(Country.supported) { c in
                        Text("\(c.flag)  \(c.name)").tag(c)
                    }
                }
                .pickerStyle(.inline)
                .labelsHidden()
            }

            Section("Notifications") {
                Label("Local reminders only in v1", systemImage: "bell.badge")
                    .font(Theme.Font.body(14))
                    .foregroundStyle(Theme.Color.muted)
            }

            Section("About") {
                LabeledContent("Version", value: appVersion)
                LabeledContent("Made by", value: "brekzware")
            }
        }
        .scrollContentBackground(.hidden)
        .background(Theme.Color.background)
        .navigationTitle("Settings")
    }

    private var appVersion: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.1"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(v) (\(b))"
    }
}

#Preview {
    NavigationStack { SettingsView() }
        .environment(AppEnvironment.shared)
}
