import SwiftUI

struct PaperclipGlossShape: Shape {
    nonisolated func path(in rect: CGRect) -> Path {
        let scaleX = rect.width / 27
        let scaleY = rect.height / 57
        func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(
                x: (x - 7) * scaleX + rect.minX,
                y: (y - 4) * scaleY + rect.minY
            )
        }

        var path = Path()
        path.move(to: point(10.53, 11.77))
        path.addQuadCurve(
            to: point(23.47, 11.77),
            control: point(17, 5.5)
        )
        return path
    }
}
