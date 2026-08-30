# Notejot

Notejot is a local-first macOS notes app built with SwiftUI. It combines a
compact sidebar and rich-text editor with the app's Quantum Paper visual style.

## Features

- List and grid views with search, tags, pinning, and Trash
- Rich-text formatting and up to four inline images per note
- Deterministic Quantum Paper colors driven by note tags
- Local JSON persistence with no network entitlement
- Native macOS menus, About panel, window behavior, and App Sandbox support

## Requirements

- macOS 26 or later
- Xcode with the macOS 26 SDK

## Build and test

Open `Notejot.xcodeproj` in Xcode, select the `Notejot` scheme, and run the app.
The equivalent command-line checks are:

```bash
swift test --package-path lib
xcodebuild -project Notejot.xcodeproj -scheme Notejot -configuration Debug build
```

## Repository layout

- `src/Notejot/` — app source, grouped by UI feature
- `lib/` — independent `NotejotCore` Swift package used by Notejot, with its
  own sources and library tests
- `data/` — asset catalog, localization, privacy manifest, migration data, and app icon
- `tests/` — home for app-level tests

## Data

Notes are stored locally at:

```text
~/Library/Application Support/notejot/notes.json
```

Existing notes in the former `minnote` support directory are migrated
automatically. The original bundle identifier is intentionally retained so an
upgrade can continue accessing the same sandbox container.

## Sharing builds

An unsigned or ad-hoc-signed build is suitable for local development. A
frictionless build for other Macs should be signed with a Developer ID
certificate and notarized; App Store distribution additionally requires the
appropriate Apple Developer Program membership and review metadata.
