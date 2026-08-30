import SwiftUI

struct PaperclipBodyShape: Shape {
    nonisolated func path(in rect: CGRect) -> Path {
        let scaleX = rect.width / 27
        let scaleY = rect.height / 57
        func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(
                x: (x - 7) * scaleX + rect.minX,
                y: (y - 4) * scaleY + rect.minY
            )
        }

        // Exact cubic representation of the original SVG's three semicircular
        // arcs. Using Path.addArc here reverses the SVG sweep in SwiftUI's
        // coordinate system and collapses the clip into a short M shape.
        var path = Path()
        path.move(to: point(30.5, 15))
        path.addLine(to: point(30.5, 48))
        path.addCurve(
            to: point(21, 57.5),
            control1: point(30.5, 53.2467),
            control2: point(26.2467, 57.5)
        )
        path.addCurve(
            to: point(11.5, 48),
            control1: point(15.7533, 57.5),
            control2: point(11.5, 53.2467)
        )
        path.addLine(to: point(11.5, 13.5))
        path.addCurve(
            to: point(17, 8),
            control1: point(11.5, 10.4624),
            control2: point(13.9624, 8)
        )
        path.addCurve(
            to: point(22.5, 13.5),
            control1: point(20.0376, 8),
            control2: point(22.5, 10.4624)
        )
        path.addLine(to: point(22.5, 45))
        path.addCurve(
            to: point(20.6, 46.9),
            control1: point(22.5, 46.0493),
            control2: point(21.6493, 46.9)
        )
        path.addCurve(
            to: point(18.7, 45),
            control1: point(19.5507, 46.9),
            control2: point(18.7, 46.0493)
        )
        path.addLine(to: point(18.7, 18))
        return path
    }
}
