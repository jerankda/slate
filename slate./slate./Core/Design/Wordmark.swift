import SwiftUI

struct Wordmark: View {
    var size: CGFloat = 28
    var body: some View {
        HStack(spacing: 0) {
            Text("slate")
                .font(.system(size: size, weight: .black, design: .rounded))
                .foregroundStyle(Theme.Color.ink)
            Text(".")
                .font(.system(size: size, weight: .black, design: .rounded))
                .foregroundStyle(Theme.Color.accent)
        }
        .kerning(-0.5)
    }
}

struct EditorialHeader: View {
    let eyebrow: String
    let title: String
    var trailing: AnyView? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            HStack {
                Text(eyebrow.uppercased())
                    .font(.system(size: 11, weight: .heavy))
                    .kerning(1.5)
                    .foregroundStyle(Theme.Color.muted)
                Spacer()
                trailing
            }
            Text(title)
                .font(.system(size: 34, weight: .black, design: .default))
                .foregroundStyle(Theme.Color.ink)
                .kerning(-0.5)
        }
        .padding(.horizontal, Theme.Spacing.l)
        .padding(.top, Theme.Spacing.m)
        .padding(.bottom, Theme.Spacing.s)
    }
}

struct SectionHeader: View {
    let title: String
    let trailing: String?

    init(_ title: String, trailing: String? = nil) {
        self.title = title
        self.trailing = trailing
    }

    var body: some View {
        HStack {
            Text(title.uppercased())
                .font(.system(size: 11, weight: .heavy))
                .kerning(1.3)
                .foregroundStyle(Theme.Color.muted)
            Spacer()
            if let trailing {
                Text(trailing)
                    .font(.system(size: 11, weight: .heavy))
                    .kerning(1.0)
                    .foregroundStyle(Theme.Color.muted)
            }
        }
        .padding(.horizontal, Theme.Spacing.l)
        .padding(.top, Theme.Spacing.l)
        .padding(.bottom, Theme.Spacing.s)
    }
}

extension Sport {
    /// Monochrome tint of the brand accent. Plan §12: per-sport accents are tints, not a rainbow.
    var tintOpacity: Double {
        switch slug {
        case "soccer": return 1.00
        case "boxing": return 0.85
        case "mma":    return 0.70
        case "nba":    return 0.55
        case "nfl":    return 0.40
        case "mlb":    return 0.25
        default:       return 1.00
        }
    }
    var tint: Color {
        Theme.Color.accent.opacity(tintOpacity)
    }
}
