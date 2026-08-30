import Observation
import SwiftUI

@MainActor
@Observable
final class PrivacyPolicyPresenter {
    var isPresented = false

    func show() {
        isPresented = true
    }
}

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Privacy at Notejot", systemImage: "lock.shield.fill")
                            .font(NotejotTypography.viewTitle)
                        Text("Notejot is a local-first notes app. It does not collect, transmit, sell, or share your personal data.")
                            .font(NotejotTypography.body)
                            .foregroundStyle(.secondary)
                    }

                    VStack(alignment: .leading, spacing: 20) {
                        PrivacyPolicySection(
                            title: "Your notes and attachments",
                            systemImage: "internaldrive",
                            text: "Notes, tags, and attached images stay in this app’s local storage on your device. Notejot has no accounts, analytics, advertising, tracking, or third-party SDKs."
                        )
                        PrivacyPolicySection(
                            title: "Choosing an image",
                            systemImage: "photo",
                            text: "When you choose an image, the system picker grants read-only access only to that selection. Notejot creates a local copy for the note and does not upload the image anywhere."
                        )
                        PrivacyPolicySection(
                            title: "Retention and deletion",
                            systemImage: "trash",
                            text: "Your content remains on your device until you move a note to Trash and choose Delete Permanently. You can also remove locally stored app data through your device’s standard app-management controls."
                        )
                        PrivacyPolicySection(
                            title: "Policy updates",
                            systemImage: "clock.arrow.circlepath",
                            text: "If Notejot’s data practices change, this policy and the App Store privacy information will be updated before the change is released."
                        )
                    }
                }
                .padding(28)
                .frame(maxWidth: 680, alignment: .leading)
                .background(
                    NotejotColors.itemSurface,
                    in: RoundedRectangle(cornerRadius: NotejotColors.largeSurfaceRadius, style: .continuous)
                )
            }
            .navigationTitle("Privacy Policy")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done", action: dismiss.callAsFunction)
                        .buttonStyle(NULButtonStyle(kind: .neutral))
                }
                .sharedBackgroundVisibility(.hidden)
            }
        }
        .frame(minWidth: 540, minHeight: 520)
        .background(NotejotColors.windowBackground(for: colorScheme))
    }
}
