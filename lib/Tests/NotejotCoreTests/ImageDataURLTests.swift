import Foundation
import Testing
@testable import NotejotCore

@Test func imageDataURLsAcceptCanonicalBase64Padding() {
    let samples = [
        "data:image/png;base64,QUJD",
        "data:image/png;base64,QUI=",
        "data:image/png;base64,QUJDRA==",
    ]

    for sample in samples {
        #expect(ImageDataURL.isValid(sample))
        #expect(ImageDataURL.decodedData(from: sample) != nil)
    }
}

@Test func imageDataURLsRejectMalformedHeadersAndPayloads() {
    let samples = [
        "image/png;base64,QUJDRA==",
        "data:image/svg+xml;base64,PHN2Zz4=",
        "data:image/png,QUJDRA==",
        "data:image/png;base64,",
        "data:image/png;base64,QUJ",
        "data:image/png;base64,QUJDRA===",
        "data:image/png;base64,QU=JDRA==",
        "data:image/png;base64,QUJ-RA==",
    ]

    for sample in samples {
        #expect(!ImageDataURL.isValid(sample))
        #expect(ImageDataURL.decodedData(from: sample) == nil)
    }
}

@Test func imageDataURLsMatchMIMETypeCaseInsensitively() {
    let source = "data:IMAGE/JPEG;base64,QUJDRA=="

    #expect(ImageDataURL.isValid(source))
    #expect(ImageDataURL.decodedData(from: source) == Data("ABCD".utf8))
}
