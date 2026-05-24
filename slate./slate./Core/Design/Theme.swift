import SwiftUI

enum Theme {
    enum Color {
        static let background = SwiftUI.Color("BackgroundColor")
        static let surface = SwiftUI.Color("SurfaceColor")
        static let surfaceElevated = SwiftUI.Color("SurfaceElevatedColor")
        static let ink = SwiftUI.Color("InkColor")
        static let muted = SwiftUI.Color("MutedColor")
        static let accent = SwiftUI.Color("AccentColor")
        static let live = SwiftUI.Color("LiveColor")
        static let hairline = SwiftUI.Color("HairlineColor")
    }

    enum Font {
        static func display(_ size: CGFloat, weight: SwiftUI.Font.Weight = .heavy) -> SwiftUI.Font {
            .system(size: size, weight: weight, design: .default)
        }
        static func body(_ size: CGFloat = 16, weight: SwiftUI.Font.Weight = .regular) -> SwiftUI.Font {
            .system(size: size, weight: weight, design: .default)
        }
        static func mono(_ size: CGFloat, weight: SwiftUI.Font.Weight = .semibold) -> SwiftUI.Font {
            .system(size: size, weight: weight, design: .default).monospacedDigit()
        }
    }

    enum Radius {
        static let card: CGFloat = 16
        static let pill: CGFloat = 999
    }

    enum Spacing {
        static let xs: CGFloat = 4
        static let s: CGFloat = 8
        static let m: CGFloat = 12
        static let l: CGFloat = 16
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
    }

    enum Motion {
        static let spring: Animation = .spring(response: 0.45, dampingFraction: 0.82)
        static let snappy: Animation = .spring(response: 0.3, dampingFraction: 0.9)
    }
}

extension View {
    func cardStyle() -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                    .fill(Theme.Color.surface)
            )
            .shadow(color: .black.opacity(0.08), radius: 24, x: 0, y: 8)
    }

    func hairlineDivider() -> some View {
        overlay(
            Rectangle()
                .fill(Theme.Color.hairline)
                .frame(height: 1),
            alignment: .bottom
        )
    }
}
