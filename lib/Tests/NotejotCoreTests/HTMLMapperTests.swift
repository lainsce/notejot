import Testing
@testable import NotejotCore

@MainActor
@Test func mapperDropsDangerousContentAndUnwrapsUnknownTags() {
    let value = HTMLMapper.attributedString(
        fromHTML: "<p>before<script>evil()</script><marquee>kept</marquee>after</p>"
    )

    #expect(!value.string.contains("evil"))
    #expect(value.string.contains("beforekeptafter"))
}

@MainActor
@Test func mapperRoundTripReachesAStableRepresentation() {
    let samples = [
        "<p>plain</p>",
        "<p><b>bold</b> and <i>italic</i></p>",
        "<h1>Heading</h1>",
        "<ul><li>one</li><li>two</li></ul>",
        "<p></p><p>leading blank survives</p>",
    ]

    for sample in samples {
        let once = HTMLMapper.html(from: HTMLMapper.attributedString(fromHTML: sample))
        let twice = HTMLMapper.html(from: HTMLMapper.attributedString(fromHTML: once))
        #expect(once == twice, "Unstable round trip for \(sample)")
    }
}

@MainActor
@Test func mapperPreservesBlankParagraphs() {
    let samples = [
        "<p>before</p><p></p><p>after</p>",
        "<p></p><p>after</p>",
        "<p>before</p><p></p>",
        "<p>before</p><p></p><p></p><p>after</p>",
    ]

    for sample in samples {
        let attributed = HTMLMapper.attributedString(fromHTML: sample)
        let roundTrip = HTMLMapper.html(from: attributed)
        #expect(roundTrip == sample, "Blank paragraph was lost in \(sample)")
    }

    #expect(
        HTMLMapper.attributedString(fromHTML: samples[0]).string == "before\n\nafter"
    )

    let blankLine = HTMLMapper.attributedString(fromHTML: samples[0])
    for index in 5...6 {
        #expect(blankLine.attribute(.font, at: index, effectiveRange: nil) != nil)
        #expect(blankLine.attribute(.paragraphStyle, at: index, effectiveRange: nil) != nil)
    }
}

@MainActor
@Test func mapperEscapesPlainTextBeforeWrappingIt() {
    #expect(
        HTMLMapper.textToHTML("<script>alert(1)</script>") ==
        "<p>&lt;script&gt;alert(1)&lt;/script&gt;</p>"
    )
}
