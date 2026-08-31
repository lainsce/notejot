import NotejotCore
import SwiftUI
import UniformTypeIdentifiers

struct NoteDetailView: View {
    @Environment(NoteStore.self) private var store
    @Environment(PermanentDeletionConfirmation.self) private var deletionConfirmation
    @Environment(\.scenePhase) private var scenePhase

    let note: Note
    var usesCompactLayout = false

    @State private var title = ""
    @State private var bodyText = NSAttributedString()
    @State private var formatter = EditorFormattingController()
    @State private var loadedTitle = ""
    @State private var loadedBody = NSAttributedString()
    @State private var isDirty = false
    @State private var detailActions = NotejotDetailActions()

    var body: some View {
        @Bindable var detailActions = detailActions

        VStack(alignment: .leading, spacing: 0) {
            TextField("Title", text: $title)
                .textFieldStyle(.plain)
                .textFieldStyle(NULTextFieldStyle())
                .font(NotejotTypography.viewTitle)
                .padding(.horizontal, titleHorizontalInset)
                .padding(.top, titleTopPadding)
                .onChange(of: title) { markDirty() }

            if !note.tags.isEmpty {
                ScrollView(.horizontal) {
                    HStack(spacing: NotejotColors.gridUnit * 2) {
                        ForEach(note.tags) { tag in
                            TagPill(tag: tag) {
                                removeTag(tag)
                            }
                        }
                    }
                    .padding(.horizontal, titleHorizontalInset)
                }
                .scrollIndicators(.hidden)
                .padding(.top, NotejotColors.gridUnit * 2)
            }

            EditorTextView(text: $bodyText, formatter: formatter)
                .padding(.horizontal, editorHorizontalInset)
                .padding(.bottom, editorHorizontalInset)
                .focusedValue(\.notejotEditorController, formatter)
                .onChange(of: bodyText) { markDirty() }
        }
        .overlay(alignment: .topTrailing) {
            if !note.images.isEmpty {
                ClipStackView(note: note)
                    // The overlay is paper-relative: lift it into the editor's
                    // 8-point gutter so the clip stands 14 points proud of the page.
                    .padding(.trailing, 8)
                    .offset(y: -14)
                    .zIndex(3)
            }
        }
        .background(QuantumPaperBackground(tags: note.tags))
        .padding(8)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if usesCompactLayout {
                CompactEditorFormattingBar(
                    formatter: formatter,
                    canAddImage: detailActions.canAddImage,
                    addImage: addImage,
                    isShowingTagPopover: $detailActions.isShowingTagPopover,
                    note: note
                )
                .frame(maxWidth: .infinity)
                .padding(.horizontal, NotejotLayoutMetrics.compactEditorHorizontalInset)
                .padding(.vertical, 8)
            }
        }
        .toolbar { editorToolbar }
        .navigationTitle("")
        .notejotToolbarBackgroundHidden()
        .focusedSceneValue(\.notejotDetailActions, detailActions)
        .fileImporter(
            isPresented: $detailActions.isShowingImageImporter,
            allowedContentTypes: [.image],
            allowsMultipleSelection: true,
            onCompletion: handleImageSelection
        )
        .onAppear {
            detailActions.update(for: note)
            loadFromNote()
        }
        .onChange(of: note) { _, newValue in
            detailActions.update(for: newValue)
        }
        .onChange(of: scenePhase) { _, newValue in
            commitWhenInactive(newValue)
        }
        .task(id: note.id) {
            await runAutosaveClock()
        }
        .onDisappear {
            saveNow()
        }
    }

    private var titleTopPadding: CGFloat {
        guard !note.images.isEmpty else { return 36 }

        // Follow the visible fan rather than reserving the four-image maximum.
        // Each additional print drops four points from the shared clip pivot.
        return 118 + CGFloat(note.images.count - 1) * clipFanStep
    }

    private var titleHorizontalInset: CGFloat {
        usesCompactLayout ? NotejotLayoutMetrics.compactTitleHorizontalInset : 40
    }

    private var editorHorizontalInset: CGFloat {
        usesCompactLayout ? NotejotLayoutMetrics.compactEditorHorizontalInset : 32
    }

    @ToolbarContentBuilder
    private var editorToolbar: some ToolbarContent {
        ToolbarItem(placement: formattingToolbarPlacement) {
            if !usesCompactLayout {
                HStack(spacing: NotejotColors.gridUnit) {
                    formatButton("Bold", systemImage: "bold", style: .bold, help: "Bold (⌘B)")
                    formatButton("Italic", systemImage: "italic", style: .italic, help: "Italic (⌘I)")
                    formatButton("Underline", systemImage: "underline", style: .underline, help: "Underline (⌘U)")
                    formatButton(
                        "Strikethrough",
                        systemImage: "strikethrough",
                        style: .strikethrough,
                        help: "Strikethrough"
                    )
                    formatButton("Bulleted List", systemImage: "list.bullet", style: .bulletList, help: "Bulleted List")

                    Divider()
                        .frame(height: 18)
                        .padding(.horizontal, 8)

                    Menu {
                        Button("Normal Text") { formatter.apply(.heading(0)) }
                        Divider()
                        Button("Heading 1") { formatter.apply(.heading(1)) }
                        Button("Heading 2") { formatter.apply(.heading(2)) }
                        Button("Heading 3") { formatter.apply(.heading(3)) }
                    } label: {
                        HStack(spacing: NotejotColors.gridUnit) {
                            NULIcon(systemImage: "textformat.size")
                            Image(systemName: "chevron.down")
                                .font(.system(size: 8, weight: .semibold))
                                .foregroundStyle(.secondary)
                        }
                        .foregroundStyle(.primary)
                    }
                    .accessibilityLabel("Heading Style")
                    .menuStyle(.borderlessButton)
                    .buttonStyle(.plain)
                    .menuIndicator(.hidden)
                    .tint(.primary)
                    .foregroundStyle(.primary)
                    .frame(
                        width: NotejotLayoutMetrics.compactToolbarControlSize,
                        height: NotejotLayoutMetrics.compactToolbarControlSize
                    )
                    .notejotToolbarHitTarget()
                    .help("Heading Style")

                    Button(action: addImage) {
                        NULIcon(
                            systemImage: "photo.badge.plus",
                            foregroundColor: .primary
                        )
                    }
                        .accessibilityLabel("Add Image")
                        .frame(
                            width: NotejotLayoutMetrics.compactToolbarControlSize,
                            height: NotejotLayoutMetrics.compactToolbarControlSize
                        )
                        .padding(.trailing, 8)
                        .notejotToolbarHitTarget()
                        .help("Add Image")
                        .disabled(!detailActions.canAddImage)
                }
                .padding(.horizontal, NotejotLayoutMetrics.compactToolbarControlInset)
                .frame(height: NotejotLayoutMetrics.compactToolbarControlSize)
                .nulToolbarSurface(
                    RoundedRectangle(
                        cornerRadius: NotejotColors.industrialSmallRadius,
                        style: .continuous
                    )
                )
                .accessibilityElement(children: .contain)
                .accessibilityLabel("Text formatting")
                .nulWindowActivityAppearance()
            }
        }
        .sharedBackgroundVisibility(.hidden)
#if os(macOS)
        ToolbarSpacer(.flexible)
            .sharedBackgroundVisibility(.hidden)
#endif

        ToolbarItem(placement: detailActionsToolbarPlacement) {
            if !usesCompactLayout {
                HStack(spacing: NotejotColors.gridUnit) {
                    Button(action: {
                        detailActions.isShowingTagPopover.toggle()
                    }) {
                        NULIcon(systemImage: "tag")
                    }
                    .accessibilityLabel("Add Tag")
                    .frame(
                        width: NotejotLayoutMetrics.compactToolbarControlSize,
                        height: NotejotLayoutMetrics.compactToolbarControlSize
                    )
                    .notejotToolbarHitTarget()
                    .help("Add Tag")
                    .popover(isPresented: $detailActions.isShowingTagPopover, arrowEdge: .bottom) {
                        TagPopoverView(note: note)
                            .presentationBackground(NotejotColors.itemSurface)
                    }

                    if note.isTrashed {
                        Menu {
                            Button("Restore") { store.restoreNote(id: note.id) }
                            Button("Delete Permanently…", role: .destructive) {
                                deletionConfirmation.request(for: note)
                            }
                            .foregroundStyle(NotejotColors.destructive)
                        } label: {
                            HStack(spacing: NotejotColors.gridUnit) {
                                NULIcon(systemImage: "ellipsis")
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 8, weight: .semibold))
                                    .foregroundStyle(.secondary)
                            }
                            .foregroundStyle(.primary)
                        }
                        .accessibilityLabel("Trash Actions")
                        .menuStyle(.button)
                        .buttonStyle(.borderless)
                        .menuIndicator(.hidden)
                        .frame(
                            width: NotejotLayoutMetrics.compactToolbarControlSize,
                            height: NotejotLayoutMetrics.compactToolbarControlSize
                        )
                        .notejotToolbarHitTarget()
                        .help("Trash Actions")
                    } else {
                        Button(action: {
                            store.trashNote(id: note.id)
                        }) {
                            NULIcon(
                                systemImage: "trash",
                                foregroundColor: .primary
                            )
                        }
                        .accessibilityLabel("Move to Trash")
                        .frame(
                            width: NotejotLayoutMetrics.compactToolbarControlSize,
                            height: NotejotLayoutMetrics.compactToolbarControlSize
                        )
                        .notejotToolbarHitTarget()
                        .foregroundStyle(NotejotColors.contentSurface)
                        .help("Move to Trash")
                    }
                }
                .padding(.horizontal, NotejotLayoutMetrics.compactToolbarControlInset)
                .frame(height: NotejotLayoutMetrics.compactToolbarControlSize)
                .nulToolbarSurface(
                    RoundedRectangle(
                        cornerRadius: NotejotColors.industrialSmallRadius,
                        style: .continuous
                    )
                )
                .accessibilityElement(children: .contain)
                .accessibilityLabel("Note actions")
                .nulWindowActivityAppearance()
            }
        }
        .sharedBackgroundVisibility(.hidden)
    }

    private func formatButton(
        _ title: String,
        systemImage: String,
        style: EditorFormattingController.Style,
        help: String
    ) -> some View {
        Button(action: {
            formatter.apply(style)
        }) {
            NULIcon(systemImage: systemImage)
        }
        .accessibilityLabel(title)
        .frame(
            width: NotejotLayoutMetrics.compactToolbarControlSize,
            height: NotejotLayoutMetrics.compactToolbarControlSize
        )
        .notejotToolbarHitTarget()
        .help(help)
    }

    private var formattingToolbarPlacement: ToolbarItemPlacement {
#if os(macOS)
        // The detail view owns the trailing toolbar region in a three-column
        // split view. This keeps formatting controls over the paper instead of
        // the note list.
        .automatic
#else
        .navigation
#endif
    }

    private var detailActionsToolbarPlacement: ToolbarItemPlacement {
#if os(macOS)
        .automatic
#else
        .primaryAction
#endif
    }

    private func addImage() {
        detailActions.addImage()
    }

    private func handleImageSelection(_ result: Result<[URL], any Error>) {
        switch result {
        case .success(let urls):
            importImages(from: urls)
        case .failure(let error):
            guard (error as? CocoaError)?.code != .userCancelled else { return }
            store.reportError("The selected image could not be imported.")
        }
    }

    private func importImages(from selectedURLs: [URL]) {
        let remaining = NoteStore.maxImages - note.images.count
        let urls = Array(selectedURLs.prefix(remaining))
        guard !urls.isEmpty else { return }
        detailActions.isImportingImages = true
        Task {
            let result = await ImageImporter.shared.importImages(from: urls, limit: remaining)
            detailActions.isImportingImages = false
            guard !result.dataURLs.isEmpty else {
                if result.failedCount > 0 {
                    store.reportError("The selected image could not be imported.")
                }
                return
            }
            store.appendImages(id: note.id, images: result.dataURLs)
            if result.failedCount > 0 {
                store.reportError("Some selected images could not be imported.")
            }
        }
    }

    private func removeTag(_ tag: Tag) {
        store.setTags(
            id: note.id,
            tags: note.tags.filter { $0.id != tag.id }
        )
    }

    private func loadFromNote() {
        title = note.title
        bodyText = HTMLMapper.attributedString(fromHTML: note.content)
        loadedTitle = title
        loadedBody = bodyText
        isDirty = false
    }

    private func markDirty() {
        guard title != loadedTitle || !bodyText.isEqual(to: loadedBody) else { return }
        isDirty = true
    }

    private func runAutosaveClock() async {
        while !Task.isCancelled {
            do {
                try await Task.sleep(for: .seconds(2))
            } catch {
                return
            }
            saveNow()
        }
    }

    private func commitWhenInactive(_ phase: ScenePhase) {
        guard phase != .active else { return }
        saveNow()
        Task {
            await store.flush()
        }
    }

    private func saveNow() {
        guard isDirty else { return }
        let html = HTMLMapper.html(from: bodyText)
        guard title != note.title || html != note.content else {
            isDirty = false
            return
        }
        store.updateNoteContent(id: note.id, title: title, content: html)
        loadedTitle = title
        loadedBody = bodyText
        isDirty = false
    }
}
