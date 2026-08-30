import SwiftUI

struct PrivacyPolicySection: View {
    let title: LocalizedStringKey
    let systemImage: String
    let text: LocalizedStringKey

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: systemImage)
                .font(NotejotTypography.contentBlockTitle)
            Text(text)
                .font(NotejotTypography.body)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
