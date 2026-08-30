import SwiftUI

enum NotejotMotion {
    /// A short, damped spring keeps selection and navigation changes connected
    /// without the bounce of a decorative animation.
    static let navigation = Animation.spring(response: 0.34, dampingFraction: 0.84)
    static let control = Animation.spring(response: 0.24, dampingFraction: 0.88)

    static func controlAnimation(reduceMotion: Bool) -> Animation? {
        reduceMotion ? nil : control
    }

    static func navigationAnimation(reduceMotion: Bool) -> Animation? {
        reduceMotion ? nil : navigation
    }
}
