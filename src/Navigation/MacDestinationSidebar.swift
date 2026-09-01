#if os(macOS)
import NotejotCore
import SwiftUI

struct MacDestinationSidebar: View {
    private enum Source: Hashable {
        case allNotes
        case tag(TagFacet.ID)
        case trash
    }

    let tagFacets: [TagFacet]
    @Binding var destination: Destination
    @Binding var selectedTagID: TagFacet.ID?

    @State private var selectedSource: Source?
    @State private var hoveredSource: Source?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        List {
            Text("Destinations").font(NotejotTypography.viewTitle)
            Section {
                destinationRow(source: .allNotes) {
                    destinationLabel("All Notes", systemImage: "note.text")
                }

                destinationRow(source: .trash) {
                    destinationLabel("Trash", systemImage: "trash")
                }
            }

            Divider()

            Section {
                if tagFacets.isEmpty {
                    Text("No Tags")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, SidebarMetrics.horizontalInset)
                        .padding(.vertical, NotejotColors.gridUnit)
                        .listRowInsets(
                            EdgeInsets(
                                top: 0,
                                leading: SidebarMetrics.horizontalInset,
                                bottom: 0,
                                trailing: SidebarMetrics.horizontalInset
                            )
                        )
                } else {
                    ForEach(tagFacets) { facet in
                        destinationRow(source: .tag(facet.id)) {
                            Label {
                                HStack {
                                    Text(facet.name)
                                    Spacer(minLength: 0)
                                    Text(facet.count, format: .number)
                                        .font(NotejotTypography.technicalFont(.body))
                                        .foregroundStyle(.secondary)
                                }
                            } icon: {
                                TagMarker(tag: facet.tag, size: 12)
                                    .accessibilityHidden(true)
                            }
                        }
                    }
                }
            } header: {
                sidebarSectionHeader("Tags")
            }
        }
        .listStyle(.sidebar)
        .scrollContentBackground(.hidden)
        .background(NotejotColors.sidebarBackground(for: colorScheme))
        .listRowSeparator(.hidden)
        .environment(\.defaultMinListRowHeight, 38)
        .onAppear(perform: synchronizeSelection)
        .onChange(of: selectedSource) { _, newSource in
            select(newSource)
        }
        .onChange(of: destination) {
            synchronizeSelection()
        }
        .onChange(of: selectedTagID) {
            synchronizeSelection()
        }
        .onChange(of: tagFacets) {
            synchronizeSelection()
        }
    }

    @ViewBuilder
    private func destinationRow<Content: View>(
        source: Source,
        @ViewBuilder content: () -> Content
    ) -> some View {
        Button {
            selectedSource = source
        } label: {
            content()
        }
        .buttonStyle(
            NULSidebarButtonStyle(
                isSelected: selectedSource == source,
                isHovered: hoveredSource == source
            )
        )
        .onHover { isHovered in
            if isHovered {
                hoveredSource = source
            } else if hoveredSource == source {
                hoveredSource = nil
            }
        }
        .accessibilityAddTraits(selectedSource == source ? .isSelected : [])
        .listRowBackground(Color.clear)
    }

    private func destinationLabel(
        _ title: LocalizedStringKey,
        systemImage: String
    ) -> some View {
        Label {
            Text(title)
                .font(NotejotTypography.contentBlockSubtitle)
        } icon: {
            Image(systemName: systemImage)
                .font(.system(size: 16, weight: .regular))
                .accessibilityHidden(true)
        }
    }

    private func sidebarSectionHeader(_ title: LocalizedStringKey) -> some View {
        Text(title)
            .font(NotejotTypography.caption)
            .tracking(0.9)
            .foregroundStyle(.secondary)
            .textCase(.uppercase)
    }

    private var currentSource: Source {
        switch destination {
        case .notes:
            selectedTagID.map(Source.tag) ?? .allNotes
        case .trash:
            .trash
        }
    }

    private func synchronizeSelection() {
        selectedSource = currentSource
    }

    private func select(_ source: Source?) {
        guard let source else {
            synchronizeSelection()
            return
        }

        withAnimation(NotejotMotion.navigationAnimation(reduceMotion: reduceMotion)) {
            apply(source)
        }
    }

    private func apply(_ source: Source) {
        switch source {
        case .allNotes:
            selectedTagID = nil
            destination = .notes
        case .tag(let tagID):
            selectedTagID = tagID
            destination = .notes
        case .trash:
            selectedTagID = nil
            destination = .trash
        }
    }
}

#endif
