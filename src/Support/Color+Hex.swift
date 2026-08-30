import SwiftUI

extension Color {
    init?(hex: String) {
        let string = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        guard string.count == 6, let value = UInt64(string, radix: 16) else { return nil }
        self.init(
            red: Double((value >> 16) & 0xFF) / 255,
            green: Double((value >> 8) & 0xFF) / 255,
            blue: Double(value & 0xFF) / 255
        )
    }
}
