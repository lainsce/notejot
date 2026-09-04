#if os(macOS)
import AppKit
#elseif os(iOS)
import UIKit
#endif

@MainActor
enum NotejotPermissionActions {
    static func openSystemSettings() {
#if os(macOS)
        guard let url = URL(
            string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone"
        ) else {
            return
        }
        NSWorkspace.shared.open(url)
#elseif os(iOS)
        guard let url = URL(string: UIApplication.openSettingsURLString) else {
            return
        }
        UIApplication.shared.open(url)
#endif
    }
}
