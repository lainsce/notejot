import NotejotCore
import Observation

@MainActor
@Observable
final class NotejotDetailActions {
    var isShowingImageImporter = false
    var isShowingTagPopover = false
    var isImportingImages = false

    private var imageCount = 0
    private var isTrashed = false

    var canAddImage: Bool {
        imageCount < NoteStore.maxImages && !isTrashed && !isImportingImages
    }

    func update(for note: Note) {
        imageCount = note.images.count
        isTrashed = note.isTrashed
    }

    func addImage() {
        guard canAddImage else { return }
        isShowingImageImporter = true
    }

    func addTag() {
        guard !isTrashed else { return }
        isShowingTagPopover = true
    }
}
