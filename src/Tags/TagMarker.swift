import SwiftUI
import NotejotCore

struct TagMarker: View {
    let tag: Tag
    let size: Double

    @Environment(\.accessibilityDifferentiateWithoutColor) private var differentiateWithoutColor

    var body: some View {
        Image(systemName: differentiateWithoutColor ? differentiatedSymbol : "circle.fill")
            .resizable()
            .scaledToFit()
            // Tag colors are user-authored data. Keep them exact and fully
            // saturated; the surrounding neutral surfaces provide contrast.
            .foregroundStyle(Color(hex: tag.color) ?? NotejotColors.accent)
            .frame(width: size, height: size)
            .accessibilityLabel("Tag \(tag.name)")
    }

    private var differentiatedSymbol: String {
        let symbols = ["circle.fill", "square.fill", "diamond.fill", "triangle.fill"]
        let index = tag.id.utf8.reduce(0) { ($0 + Int($1)) % symbols.count }
        return symbols[index]
    }
}
