import SwiftUI

struct NoteCardExcerpt: View {
    let text: String
    let lineLimit: Int

    var body: some View {
        Text(text)
            .font(NotejotTypography.body)
            .foregroundStyle(.secondary)
            .lineSpacing(1)
            .lineLimit(lineLimit)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityLabel(text)
    }
}
