import NotejotCore
import SwiftUI

let clipPrintWidth: CGFloat = 156
let clipPrintHeight: CGFloat = 104
let clipFanStep: CGFloat = 4
let clipOverhang: CGFloat = 22

struct ClipStackView: View {
    let note: Note

    @State private var isShowingFlyout = false

    var body: some View {
        let images = note.images
        let fanHeight = clipPrintHeight + CGFloat(max(images.count - 1, 0)) * clipFanStep

        Button {
            isShowingFlyout = true
        } label: {
            ZStack(alignment: .top) {
                ZStack {
                    ForEach(images.enumerated(), id: \.offset) { index, source in
                        ClipPrintView(source: source, index: index, total: images.count)
                            .zIndex(Double(index + 1))
                    }
                }
                .frame(width: clipPrintWidth, height: fanHeight)
                .offset(y: clipOverhang)

                PaperclipView()
                    .frame(width: 26, height: 55)
                    .zIndex(10)
            }
            .frame(
                width: clipPrintWidth + 28,
                height: clipOverhang + fanHeight + clipOverhang,
                alignment: .top
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text("View ^[\(images.count) attached image](inflect: true)"))
        .help("View attached images")
        .sheet(isPresented: $isShowingFlyout) {
            ImageFlyoutView(note: note)
        }
    }
}
