import NotejotCore
import SwiftUI

struct TagFilterShelf: View {
    let facets: [TagFacet]
    let allNoteCount: Int
    @Binding var selection: TagFacet.ID?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: SidebarMetrics.horizontalSpacing) {
                TagFilterChip(
                    tag: nil,
                    count: allNoteCount,
                    isSelected: selection == nil,
                    action: showAllNotes
                )

                ForEach(facets) { facet in
                    TagFilterChip(
                        tag: facet.tag,
                        count: facet.count,
                        isSelected: selection == facet.id
                    ) {
                        select(facet.id)
                    }
                }
            }
            .padding(.horizontal, SidebarMetrics.horizontalInset)
        }
        .scrollIndicators(.hidden)
        .frame(
            height: NotejotLayoutMetrics.smallInteractiveControlSize
                + SidebarMetrics.verticalSpacing
        )
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Filter notes by tag")
    }

    private func showAllNotes() {
        withAnimation(NotejotMotion.controlAnimation(reduceMotion: reduceMotion)) {
            selection = nil
        }
    }

    private func select(_ id: TagFacet.ID) {
        withAnimation(NotejotMotion.controlAnimation(reduceMotion: reduceMotion)) {
            selection = selection == id ? nil : id
        }
    }
}
