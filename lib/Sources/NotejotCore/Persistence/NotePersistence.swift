import Foundation

actor NotePersistence {
    struct LoadResult: Sendable {
        let file: NoteFile?
        let errorMessage: String?
    }

    private var directory: URL
    private var newestGeneration = 0

    init(directory: URL) {
        self.directory = directory
    }

    func load() -> LoadResult {
        directory = resolvedDirectory()
        let storeURL = directory.appending(path: "notes.json")
        guard FileManager.default.fileExists(atPath: storeURL.path) else {
            return LoadResult(file: nil, errorMessage: nil)
        }

        do {
            let data = try Data(contentsOf: storeURL, options: .mappedIfSafe)
            let file = try JSONDecoder().decode(NoteFile.self, from: data)
            return LoadResult(file: file, errorMessage: nil)
        } catch {
            let backupURL = availableCorruptBackupURL(for: storeURL)
            do {
                try FileManager.default.moveItem(at: storeURL, to: backupURL)
                return LoadResult(
                    file: nil,
                    errorMessage: String(
                        localized: "The notes file could not be read and was preserved as \(backupURL.lastPathComponent).",
                        bundle: #bundle,
                        comment: "Error shown after preserving an unreadable notes file; the variable is its backup filename."
                    )
                )
            } catch let quarantineError {
                return LoadResult(
                    file: nil,
                    errorMessage: String(
                        localized: "The notes file could not be read or preserved: \(quarantineError.localizedDescription)",
                        bundle: #bundle,
                        comment: "Error shown when an unreadable notes file also could not be preserved; the variable is the system error."
                    )
                )
            }
        }
    }

    func save(_ file: NoteFile, generation: Int) -> String? {
        guard generation >= newestGeneration else { return nil }
        newestGeneration = generation

        do {
            try FileManager.default.createDirectory(
                at: directory,
                withIntermediateDirectories: true
            )
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .withoutEscapingSlashes, .sortedKeys]
            let data = try encoder.encode(file)
            try data.write(to: directory.appending(path: "notes.json"), options: .atomic)
            return nil
        } catch {
            return error.localizedDescription
        }
    }

    private func resolvedDirectory() -> URL {
        guard directory.lastPathComponent == "notejot" else { return directory }

        let legacyDirectory = directory
            .deletingLastPathComponent()
            .appending(path: "minnote", directoryHint: .isDirectory)
        guard !FileManager.default.fileExists(atPath: directory.path),
              FileManager.default.fileExists(atPath: legacyDirectory.path) else {
            return directory
        }

        do {
            try FileManager.default.moveItem(at: legacyDirectory, to: directory)
            return directory
        } catch {
            return legacyDirectory
        }
    }

    private func availableCorruptBackupURL(for storeURL: URL) -> URL {
        let firstChoice = storeURL.appendingPathExtension("corrupt")
        guard FileManager.default.fileExists(atPath: firstChoice.path) else {
            return firstChoice
        }

        var suffix = 2
        while true {
            let candidate = storeURL.appendingPathExtension("corrupt-\(suffix)")
            if !FileManager.default.fileExists(atPath: candidate.path) {
                return candidate
            }
            suffix += 1
        }
    }
}
