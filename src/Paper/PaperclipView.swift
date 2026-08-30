import SwiftUI

struct PaperclipView: View {
    var body: some View {
        ZStack {
            PaperclipBodyShape()
                .stroke(
                    Color.primary.opacity(0.78),
                    style: StrokeStyle(lineWidth: 6, lineCap: .round, lineJoin: .round)
                )
        }
        .accessibilityHidden(true)
    }
}
