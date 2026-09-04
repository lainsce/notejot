import NotejotCore
import SwiftUI

struct TagPopoverView: View {
    let note: Note

    @Environment(NoteStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isTagNameFocused: Bool
    @State private var tagName = ""
    @State private var selectedColor = TagPalette.defaultColor

    private var availableTagFacets: [TagFacet] {
        let currentTagIDs = Set(note.tags.map(\.facetID))
        return TagFacet.available(in: store.notes)
            .filter { !currentTagIDs.contains($0.id) }
    }

    private var pendingTag: Tag {
        let fallbackName = TagPalette.colors.first(where: { $0.hex == selectedColor })
            .map { String(localized: $0.name) }
            ?? String(localized: "Tag")
        let name = tagName.trimmingCharacters(in: .whitespacesAndNewlines)
        return Tag(color: selectedColor, name: name.isEmpty ? fallbackName : name)
    }

    private var canAddPendingTag: Bool {
        !note.tags.contains { $0.facetID == pendingTag.facetID }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !availableTagFacets.isEmpty {
                Text("Use Existing Tag")
                    .font(NotejotTypography.caption)
                    .tracking(0.7)
                    .foregroundStyle(.secondary)

                ScrollView {
                    LazyVStack(alignment: .leading, spacing: NotejotColors.gridUnit) {
                        ForEach(availableTagFacets) { facet in
                            AvailableTagRow(facet: facet) {
                                addExistingTag(facet)
                            }
                        }
                    }
                }
                .frame(maxHeight: 140)

            }

            Text("Create Tag")
                .font(NotejotTypography.caption)
                .tracking(0.7)
                .foregroundStyle(.secondary)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: NotejotColors.gridUnit * 2) {
                ForEach(TagPalette.colors, id: \.hex) { item in
                    TagColorSwatch(
                        hex: item.hex,
                        name: item.name,
                        isSelected: selectedColor == item.hex
                    ) {
                        selectedColor = item.hex
                    }
                }
            }

            HStack(alignment: .center, spacing: 8) {
                Text("Name")
                    .foregroundStyle(.secondary)
                    .frame(width: 48, alignment: .leading)

                TextField("", text: $tagName, prompt: Text("Optional"))
                    .textFieldStyle(.plain)
                    .textFieldStyle(NULTextFieldStyle())
                    .focused($isTagNameFocused)
                    .accessibilityLabel("Name")
            }

            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                    .buttonStyle(NULButtonStyle(kind: .neutral))
                    .frame(minHeight: NotejotLayoutMetrics.minimumInteractiveControlSize)
                    .contentShape(.rect(cornerRadius: NotejotColors.controlRadius))
                Button("Create", action: addTag)
                    .buttonStyle(NULButtonStyle(kind: .primary))
                    .frame(minHeight: NotejotLayoutMetrics.minimumInteractiveControlSize)
                    .contentShape(.rect(cornerRadius: NotejotColors.controlRadius))
                    .disabled(!canAddPendingTag)
            }
        }
        .padding(16)
        .background(
            NotejotColors.itemSurface,
            in: RoundedRectangle(cornerRadius: NotejotColors.largeSurfaceRadius, style: .continuous)
        )
        .frame(width: NotejotLayoutMetrics.popoverWidth)
    }

    private func addTag() {
        guard canAddPendingTag else { return }
        let reusableTag = TagFacet.available(in: store.notes)
            .first { $0.id == pendingTag.facetID }?.tag
        store.setTags(
            id: note.id,
            tags: note.tags + [reusableTag ?? pendingTag]
        )
        dismiss()
    }

    private func addExistingTag(_ facet: TagFacet) {
        store.setTags(id: note.id, tags: note.tags + [facet.tag])
        dismiss()
    }
}
