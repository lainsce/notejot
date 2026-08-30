#if canImport(AppKit)
import AppKit
import NotejotCore

@MainActor
final class NotejotApplicationDelegate: NSObject, NSApplicationDelegate {
    weak var store: NoteStore?

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        guard let store, store.hasPendingSave else { return .terminateNow }
        Task {
            await store.flush()
            sender.reply(toApplicationShouldTerminate: true)
        }
        return .terminateLater
    }
}
#endif
