import AppKit
import AVFoundation
import ImageIO
import SwiftUI
import XCTest
import NotejotCore
@testable import Notejot

final class NotejotAppTests: XCTestCase {
    private func pngData(width: Int, height: Int) -> Data {
        let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
        let pixels = [UInt8](repeating: 0x7F, count: width * height * 4)
        let provider = CGDataProvider(data: Data(pixels) as CFData)!
        let image = CGImage(
            width: width,
            height: height,
            bitsPerComponent: 8,
            bitsPerPixel: 32,
            bytesPerRow: width * 4,
            space: colorSpace,
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
            provider: provider,
            decode: nil,
            shouldInterpolate: false,
            intent: .defaultIntent
        )!
        let output = NSMutableData()
        let destination = CGImageDestinationCreateWithData(output, "public.png" as CFString, 1, nil)!
        CGImageDestinationAddImage(destination, image, nil)
        XCTAssertTrue(CGImageDestinationFinalize(destination))
        return output as Data
    }

    @MainActor
    func testSceneModelNavigationAndNoteActions() async {
        let directory = FileManager.default.temporaryDirectory
            .appending(path: "NotejotTests-\(UUID().uuidString)", directoryHint: .isDirectory)
        let store = NoteStore(directory: directory)
        let deletion = PermanentDeletionConfirmation()
        let model = NotejotSceneModel(store: store, deletionConfirmation: deletion)

        await model.prepare()
        XCTAssertTrue(model.hasSelection)
        XCTAssertEqual(model.activeNoteCount, 1)
        XCTAssertEqual(model.trashNoteCount, 0)

        model.createNote()
        XCTAssertTrue(model.hasSelection)
        XCTAssertEqual(model.compactPath.count, 1)
        let createdID = try! XCTUnwrap(model.selection)
        model.togglePin()
        model.refreshFromStore()
        XCTAssertTrue(model.selectedNoteIsPinned)
        model.moveToTrash()
        model.refreshFromStore()
        XCTAssertTrue(store.notes.first(where: { $0.id == createdID })?.isTrashed == true)

        model.showTrash()
        model.refreshFromStore()
        XCTAssertTrue(model.selectedNoteIsTrashed)
        model.showGrid()
        XCTAssertEqual(model.viewMode, .grid)
        model.searchNotes()
        XCTAssertTrue(model.isSearchPresented)
        model.toggleSearch()
        XCTAssertFalse(model.isSearchPresented)
        model.restore()
        model.refreshFromStore()
        XCTAssertFalse(store.notes.first(where: { $0.id == createdID })?.isTrashed == true)
        model.showNotes()
        model.showList()
        XCTAssertEqual(model.viewMode, .list)
    }

    @MainActor
    func testDeletionConfirmationRejectsLiveNotesAndClears() async {
        let directory = FileManager.default.temporaryDirectory
            .appending(path: "NotejotTests-\(UUID().uuidString)", directoryHint: .isDirectory)
        let store = NoteStore(directory: directory)
        await store.load()
        let live = store.createNote()
        let confirmation = PermanentDeletionConfirmation()

        confirmation.request(for: live)
        XCTAssertFalse(confirmation.isPresented)
        XCTAssertEqual(confirmation.noteTitle, "Untitled Note")

        var trashed = live
        trashed.isTrashed = true
        trashed.title = "  A title  "
        confirmation.request(for: trashed)
        XCTAssertTrue(confirmation.isPresented)
        XCTAssertEqual(confirmation.noteTitle, "A title")
        confirmation.clear()
        XCTAssertFalse(confirmation.isPresented)
        XCTAssertNil(confirmation.note)
    }

    @MainActor
    func testTokensAndPlatformHelpers() {
        XCTAssertEqual(NotejotLayoutMetrics.minimumWindowWidth, 390)
        XCTAssertEqual(NotejotLayoutMetrics.fieldHeight, 36)
        XCTAssertEqual(NotejotColors.gridUnit, 4)
        XCTAssertEqual(NotejotColors.formRowSpacing, 16)
        XCTAssertEqual(NotejotColors.formLabelWidth, 128)
        XCTAssertEqual(NotejotColors.fieldHorizontalPadding, 12)
        XCTAssertEqual(NotejotColors.controlRadius, 4)
        XCTAssertEqual(NotejotColors.largeSurfaceRadius, 12)
        XCTAssertEqual(TagPalette.colors.count, 8)
        XCTAssertEqual(TagPalette.defaultColor, "#4A90D9")

        XCTAssertNil(Color(hex: "#12"))
        XCTAssertNotNil(Color(hex: "#4A90D9"))
        XCTAssertNil(NotejotMotion.controlAnimation(reduceMotion: true))
        XCTAssertNotNil(NotejotMotion.controlAnimation(reduceMotion: false))
        XCTAssertNil(NotejotMotion.navigationAnimation(reduceMotion: true))
        XCTAssertNotNil(NotejotMotion.navigationAnimation(reduceMotion: false))
        XCTAssertEqual(formattedNoteDate("not-a-date"), "not-a-date")
        XCTAssertEqual(CompactRoute.note("id"), .note("id"))
        XCTAssertEqual(SidebarViewMode.list, .list)
    }

    func testPaperclipShapesProduceGeometry() {
        let rect = CGRect(x: 0, y: 0, width: 27, height: 57)
        XCTAssertFalse(PaperclipBodyShape().path(in: rect).isEmpty)
        XCTAssertGreaterThan(PaperclipBodyShape().path(in: rect).boundingRect.height, 40)
    }

    @MainActor
    func testImageImporterKeepsSmallImagesAndCompressesOversizedOnes() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appending(path: "NotejotImageImportTests-\(UUID().uuidString)", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let smallURL = directory.appending(path: "small.png")
        let oversizedURL = directory.appending(path: "oversized.png")
        try pngData(width: 8, height: 8).write(to: smallURL)
        try pngData(width: 1_700, height: 1).write(to: oversizedURL)

        let result = await ImageImporter.shared.importImages(
            from: [smallURL, oversizedURL, directory.appending(path: "missing.png")],
            limit: 3
        )
        XCTAssertEqual(result.dataURLs.count, 2)
        XCTAssertEqual(result.failedCount, 1)
        XCTAssertTrue(result.dataURLs.allSatisfy { $0.hasPrefix("data:image/png;base64,") })

        let limited = await ImageImporter.shared.importImages(from: [smallURL], limit: -1)
        XCTAssertTrue(limited.dataURLs.isEmpty)
        XCTAssertEqual(limited.failedCount, 0)
    }

    func testSpeechSamplesKeepAndResampleFloatAudio() {
        let nativeFormat = AVAudioFormat(standardFormatWithSampleRate: 16_000, channels: 1)!
        let nativeBuffer = AVAudioPCMBuffer(pcmFormat: nativeFormat, frameCapacity: 4)!
        nativeBuffer.frameLength = 4
        nativeBuffer.floatChannelData![0][0] = 0.1
        nativeBuffer.floatChannelData![0][1] = 0.2
        nativeBuffer.floatChannelData![0][2] = 0.3
        nativeBuffer.floatChannelData![0][3] = 0.4

        let samples = NoteSpeechSamples()
        samples.append(nativeBuffer)
        XCTAssertEqual(samples.snapshot().count, 4)

        let lowRateFormat = AVAudioFormat(standardFormatWithSampleRate: 8_000, channels: 1)!
        let lowRateBuffer = AVAudioPCMBuffer(pcmFormat: lowRateFormat, frameCapacity: 2)!
        lowRateBuffer.frameLength = 2
        lowRateBuffer.floatChannelData![0][0] = -0.5
        lowRateBuffer.floatChannelData![0][1] = 0.5
        let resampled = NoteSpeechSamples()
        resampled.append(lowRateBuffer)
        XCTAssertEqual(resampled.snapshot().count, 4)

        let emptyBuffer = AVAudioPCMBuffer(pcmFormat: nativeFormat, frameCapacity: 1)!
        emptyBuffer.frameLength = 0
        resampled.append(emptyBuffer)
        XCTAssertEqual(resampled.snapshot().count, 4)
    }
}
