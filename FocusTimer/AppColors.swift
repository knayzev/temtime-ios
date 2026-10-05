import SwiftUI
import UIKit

private extension UIColor {
    convenience init(hex: UInt32) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1
        )
    }
}

extension Color {
    init(hex: UInt32) {
        self.init(uiColor: UIColor(hex: hex))
    }

    /// A colour that follows the system appearance.
    init(light: UInt32, dark: UInt32) {
        self.init(uiColor: UIColor { traits in
            UIColor(hex: traits.userInterfaceStyle == .dark ? dark : light)
        })
    }
}

/// A monochrome identity: black carries actions and selection, greys carry surfaces, and one soft
/// blue is kept for progress and for whatever is live — the entry in the timer, the rest phase.
/// Every colour has a dark counterpart. The accent turns white there, which is why anything drawn
/// on it takes `onPrimary` rather than a fixed white.
enum AppColors {
    static let primary = Color(light: 0x111114, dark: 0xF2F3F5)
    static let onPrimary = Color(light: 0xFFFFFF, dark: 0x111114)
    /// The grey of a selected or secondary block.
    static let primarySoft = Color(light: 0xE9EBF0, dark: 0x2B2D33)

    static let accent = Color(light: 0x3B6FD8, dark: 0x8FB2F5)
    static let accentSoft = Color(light: 0xE6EEFC, dark: 0x1F3563)
    static let onAccentSoft = Color(light: 0x0F2A5C, dark: 0xDCE7FD)

    /// The phases are roles, not colours of their own: a fixed black ring would vanish on the
    /// dark theme.
    static let workColor = primary
    static let restColor = accent

    /// Surfaces, from the card that sits on the page to the track of a progress bar.
    static let card = Color(light: 0xFFFFFF, dark: 0x0F1012)
    static let surface = Color(light: 0xF4F5F7, dark: 0x17181B)
    static let surfaceHigh = Color(light: 0xEDEEF1, dark: 0x1F2024)
    static let track = Color(light: 0xE4E6EA, dark: 0x2A2C31)

    /// `outline` rings an empty tick and an outlined button; `hairline` borders a card.
    static let outline = Color(light: 0x9498A1, dark: 0x6B6F78)
    static let hairline = Color(light: 0xE1E3E8, dark: 0x2F3238)

    static let warning = Color(light: 0xC62828, dark: 0xFFB4AB)
    static let warningSoft = Color(light: 0xFCE4E4, dark: 0x5A0F0F)

    /// A switch keeps a white knob on both themes, so on the dark one it cannot take the white
    /// accent and takes the blue instead.
    static let switchOn = Color(light: 0x111114, dark: 0x4F7FE0)
}
