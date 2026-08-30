import Foundation

func temporaryDirectory() throws -> URL {
    let directory = URL.temporaryDirectory
        .appending(path: "notejot-tests-\(UUID().uuidString)", directoryHint: .isDirectory)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    return directory
}

func legacyFixtureURL() throws -> URL {
    if let nested = Bundle.module.url(
        forResource: "legacy-notes",
        withExtension: "json",
        subdirectory: "Fixtures"
    ) {
        return nested
    }
    guard let root = Bundle.module.url(forResource: "legacy-notes", withExtension: "json") else {
        throw CocoaError(.fileNoSuchFile)
    }
    return root
}
