import SwiftUI
import NotejotCore

@main
struct NotejotApp: App {
#if canImport(AppKit)
    @NSApplicationDelegateAdaptor(NotejotApplicationDelegate.self) private var applicationDelegate
#endif
    @State private var store = NoteStore(directory: NoteStore.defaultDirectory())
    @State private var deletionConfirmation = PermanentDeletionConfirmation()
    @State private var privacyPolicyPresenter = PrivacyPolicyPresenter()

    init() {
        NotejotFontRegistration.register()
    }

    var body: some Scene {
#if os(macOS)
        WindowGroup {
            ContentView(
                store: store,
                deletionConfirmation: deletionConfirmation,
                privacyPolicyPresenter: privacyPolicyPresenter
            )
            .font(NotejotTypography.body)
            .environment(store)
            .environment(deletionConfirmation)
            .environment(privacyPolicyPresenter)
            .frame(minWidth: NotejotLayoutMetrics.minimumWindowWidth)
            .task {
                applicationDelegate.store = store
            }
        }
        .defaultSize(width: 1100, height: 760)
        .commands {
            NotejotMenuCommands()
        }

        Window("About Notejot", id: NotejotWindowID.about) {
            NotejotAboutView()
                .font(NotejotTypography.body)
        }
        .windowResizability(.contentSize)

        Window("Privacy Policy", id: NotejotWindowID.privacyPolicy) {
            PrivacyPolicyView()
                .font(NotejotTypography.body)
        }
        .defaultSize(width: 540, height: 520)
        .windowResizability(.contentSize)
#else
        WindowGroup {
            ContentView(
                store: store,
                deletionConfirmation: deletionConfirmation,
                privacyPolicyPresenter: privacyPolicyPresenter
            )
            .font(NotejotTypography.body)
            .environment(store)
            .environment(deletionConfirmation)
            .environment(privacyPolicyPresenter)
        }
        .commands {
            NotejotMenuCommands()
        }
#endif
    }
}
