public enum EditorBoldStyler {
    /// Toggle bold. For heading-weight fonts (weight ≥ .semibold), stepping down
    /// one weight level acts as "un-bold" rather than applying the font manager's
    /// trait toggle, which would be a no-op because the trait is already set.
    public static func toggled(_ font: NotejotFont) -> NotejotFont {
        let desc = font.fontDescriptor
        let traits = desc.symbolicTraits
        let boldTrait = PlatformTypography.boldTrait
        let isBold = traits.contains(boldTrait)
        let newTraits = isBold ? traits.subtracting(boldTrait) : traits.union(boldTrait)
        return PlatformTypography.applying(newTraits, to: font)
    }

    public static func toggledItalic(_ font: NotejotFont) -> NotejotFont {
        let desc = font.fontDescriptor
        let traits = desc.symbolicTraits
        let italicTrait = PlatformTypography.italicTrait
        let isItalic = traits.contains(italicTrait)
        let newTraits = isItalic ? traits.subtracting(italicTrait) : traits.union(italicTrait)
        return PlatformTypography.applying(newTraits, to: font)
    }
}
