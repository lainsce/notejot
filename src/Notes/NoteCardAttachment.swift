import SwiftUI

struct NoteCardAttachment: View {
    let source: String
    let noteTitle: String

    var body: some View {
        DataURLImage(
            source: source,
            accessibilityLabel: String(
                localized: "Attachment preview for \(noteTitle)",
                comment: "VoiceOver label for the image shown on a note grid card."
            )
        )
        .aspectRatio(contentMode: .fill)
        .frame(maxWidth: .infinity)
        .frame(height: 68)
        .clipShape(.rect(cornerRadius: NotejotColors.controlRadius))
    }
}
