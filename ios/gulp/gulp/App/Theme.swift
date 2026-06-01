import SwiftUI

enum Theme {
    static let background = Color(red: 0.04, green: 0.04, blue: 0.05)
    static let surface = Color(red: 0.10, green: 0.10, blue: 0.12)
    static let surfaceElevated = Color(red: 0.14, green: 0.14, blue: 0.16)
    static let hairline = Color.white.opacity(0.06)
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.6)
    static let textTertiary = Color.white.opacity(0.35)
    static let accent = Color(red: 0.96, green: 0.42, blue: 0.27)

    static let cardTop = Color(red: 0.135, green: 0.135, blue: 0.155)
    static let cardBottom = Color(red: 0.085, green: 0.085, blue: 0.105)
}

func scoreColor(_ score: Double) -> Color {
    switch score {
    case 9.0...:  return Color(red: 0.52, green: 0.78, blue: 0.55)
    case 8.0..<9: return Color(red: 0.72, green: 0.80, blue: 0.45)
    case 7.0..<8: return Color(red: 0.88, green: 0.72, blue: 0.36)
    case 6.0..<7: return Color(red: 0.88, green: 0.58, blue: 0.30)
    case 5.0..<6: return Color(red: 0.85, green: 0.45, blue: 0.32)
    default:      return Color(red: 0.74, green: 0.34, blue: 0.38)
    }
}

func scoreGradient(_ score: Double) -> LinearGradient {
    let base = scoreColor(score)
    return LinearGradient(
        colors: [base, base.opacity(0.78)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

struct ElevatedCard: ViewModifier {
    var cornerRadius: CGFloat = 20

    func body(content: Content) -> some View {
        content
            .background(
                LinearGradient(
                    colors: [Theme.cardTop, Theme.cardBottom],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.16),
                                Color.white.opacity(0.04),
                                Color.white.opacity(0.01)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1
                    )
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .shadow(color: .black.opacity(0.55), radius: 22, x: 0, y: 12)
            .shadow(color: .black.opacity(0.25), radius: 6, x: 0, y: 3)
    }
}

extension View {
    func elevatedCard(cornerRadius: CGFloat = 20) -> some View {
        modifier(ElevatedCard(cornerRadius: cornerRadius))
    }
}
