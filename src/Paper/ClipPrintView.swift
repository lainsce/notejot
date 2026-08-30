import SwiftUI

struct ClipPrintView: View {
    let source: String
    let index: Int
    let total: Int
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 3)
                .fill(NotejotColors.elevatedSurface(for: colorScheme))
            DataURLImage(source: source, accessibilityLabel: "Attached image \(index + 1)")
                .aspectRatio(contentMode: .fill)
                .frame(width: clipPrintWidth - 14, height: clipPrintHeight - 14)
                .clipShape(RoundedRectangle(cornerRadius: 2))
        }
        .frame(width: clipPrintWidth, height: clipPrintHeight)
        .offset(y: CGFloat(index) * clipFanStep)
        .rotationEffect(
            .degrees(clipTilt(source: source, index: index, total: total)),
            anchor: UnitPoint(x: 0.5, y: 10 / clipPrintHeight)
        )
    }
}

private func clipTilt(source: String, index: Int, total: Int) -> Double {
    var hash: UInt32 = 2_166_136_261
    let scalars = Array(source.unicodeScalars)
    var scalarIndex = 0
    while scalarIndex < scalars.count {
        hash ^= UInt32(scalars[scalarIndex].value)
        hash = hash &* 16_777_619
        scalarIndex += 137
    }
    hash ^= UInt32(index + 1)
    hash = hash &* 16_777_619
    let slice = 14 / Double(total)
    let jitter = (Double(hash % 1_001) / 1_000 - 0.5) * 0.56
    return -7 + slice * (Double(index) + 0.5 + jitter)
}
