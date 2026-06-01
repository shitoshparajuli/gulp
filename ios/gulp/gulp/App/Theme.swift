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
}

func scoreColor(_ score: Double) -> Color {
    switch score {
    case 9.0...:  return Color(red: 0.20, green: 0.83, blue: 0.55)
    case 8.0..<9: return Color(red: 0.55, green: 0.80, blue: 0.30)
    case 7.0..<8: return Color(red: 0.95, green: 0.78, blue: 0.20)
    case 6.0..<7: return Color(red: 0.97, green: 0.60, blue: 0.20)
    case 5.0..<6: return Color(red: 0.95, green: 0.45, blue: 0.25)
    default:      return Color(red: 0.92, green: 0.32, blue: 0.35)
    }
}

func scoreGradient(_ score: Double) -> LinearGradient {
    let base = scoreColor(score)
    return LinearGradient(
        colors: [base, base.opacity(0.75)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}
