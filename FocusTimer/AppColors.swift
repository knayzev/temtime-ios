import SwiftUI

extension Color {
    init(hex: UInt32) {
        let r = Double((hex >> 16) & 0xFF) / 255
        let g = Double((hex >> 8) & 0xFF) / 255
        let b = Double(hex & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

/// A deliberate indigo/coral/teal identity instead of the default system blue.
enum AppColors {
    static let primary = Color(hex: 0x5B4FE9)
    static let secondary = Color(hex: 0xFF7A59)
    static let workColor = Color(hex: 0x5B4FE9)
    static let restColor = Color(hex: 0x00A896)
}
