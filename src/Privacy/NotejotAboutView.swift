#if os(macOS)
import AppKit
import SwiftUI

struct NotejotAboutView: View {
    @Environment(\.openWindow) private var openWindow
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 16) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .frame(width: 128, height: 128)

            VStack(spacing: 8) {
                Text(NotejotAppInfo.applicationName)
                    .font(NotejotTypography.viewTitle)
                    .tracking(-0.4)

                Text("A quiet, local-first home for your notes.")
                    .font(NotejotTypography.viewSubtitle)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 0) {
                Text("Capture thoughts quickly, keep them local,")
                Text("and return when you need them.")
            }
            .font(NotejotTypography.body)
            .multilineTextAlignment(.center)
            .foregroundStyle(.secondary)
            .frame(maxWidth: 320)
            .accessibilityElement(children: .combine)

            VStack(spacing: 4) {
                Text("Version \(NotejotAppInfo.versionString)")
                    .font(NotejotTypography.caption)
                    .foregroundStyle(.secondary)

                Text(NotejotAppInfo.copyright)
                    .font(NotejotTypography.caption)
                    .foregroundStyle(.tertiary)

                Text("Made with SwiftUI for Mac, iPhone, and iPad.")
                    .font(NotejotTypography.caption)
                    .foregroundStyle(.tertiary)
            }

            Button("Privacy Policy") {
                openWindow(id: NotejotWindowID.privacyPolicy)
            }
            .buttonStyle(.link)
        }
        .padding(32)
        .frame(width: 420)
        .background {
            NotejotColors.surface(for: colorScheme)
        }
        .overlay(alignment: .top) {
            Rectangle()
                .fill(NotejotColors.accent)
                .frame(height: 3)
        }
    }
}
#endif
