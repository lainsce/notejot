import NotejotCore
import SwiftUI

/// Bottom-anchored note capture for the middle sidebar.
struct QuickNoteComposer: View {
    @Environment(NoteStore.self) private var store
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var recorder = NoteVoiceRecorder()
    @State private var text = ""
    @State private var listening = false
    @State private var recordingStartedAt = Date()

    var body: some View {
        VStack(spacing: 8) {
            if listening || !recorder.transcript.isEmpty {
                HStack(spacing: 8) {
                    Text(verbatim: recorder.errorDescription ?? (recorder.transcript.isEmpty ? "Listening…" : recorder.transcript))
                        .font(NotejotTypography.caption)
                        .lineLimit(3)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Button(action: saveNote) {
                        Image(systemName: "paperplane.fill")
                            .frame(width: 28, height: 28)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.black)
                    .background(NotejotColors.accent, in: Circle())
                    .accessibilityLabel("Save note")
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(NotejotColors.paperBackground(for: colorScheme), in: RoundedRectangle(cornerRadius: 12))
            }

            if listening { listeningBar } else { idleBar }
        }
        .padding(.horizontal, SidebarMetrics.horizontalInset)
        .padding(.vertical, SidebarMetrics.halfVerticalSpacing)
        .onChange(of: recorder.transcript) { _, value in
            text = value
        }
    }

    private var idleBar: some View {
        HStack(spacing: 0) {
            Button {
                recordingStartedAt = .now
                listening = true
                recorder.start()
            } label: {
                Image(systemName: "mic.fill")
                    .frame(width: 40, height: 40)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Start voice note")

            TextField("Add a note…", text: $text)
                .textFieldStyle(.plain)
                .font(NotejotTypography.caption)
                .onSubmit(saveNote)

            sendButton
        }
        .frame(height: 40)
        .padding(.leading, 4)
        .background(NotejotColors.paperBackground(for: colorScheme), in: Capsule())
    }

    private var listeningBar: some View {
        Button {
            recorder.stop()
            listening = false
        } label: {
            HStack(spacing: 0) {
                Image(systemName: "mic.fill")
                    .frame(width: 40, height: 40)
                Spacer(minLength: 0)
                HStack(spacing: 3) {
                    waveformBar(recorder.bass)
                    waveformBar(recorder.mid)
                    waveformBar(recorder.treble)
                }
                .frame(width: 24, height: 40)
                Spacer(minLength: 0)
                TimelineView(.periodic(from: .now, by: 1)) { context in
                    Text(elapsedTime(from: context.date))
                        .font(NotejotTypography.caption)
                        .monospacedDigit()
                        .frame(width: 38, alignment: .leading)
                }
                .padding(.trailing, 14)
            }
        }
        .buttonStyle(.plain)
        .foregroundStyle(.black)
        .background(NotejotColors.accent, in: Capsule())
        .accessibilityLabel("Stop recording")
    }

    private var sendButton: some View {
        Button(action: saveNote) {
            Image(systemName: "paperplane.fill")
                .frame(width: 30, height: 30)
        }
        .buttonStyle(.plain)
        .foregroundStyle(.black)
        .background(NotejotColors.accent, in: Circle())
        .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && recorder.transcript.isEmpty)
        .padding(.trailing, 4)
        .accessibilityLabel("Save note")
    }

    private func waveformBar(_ level: CGFloat) -> some View {
        Capsule()
            .fill(.black)
            .frame(width: 2, height: max(5, min(18, level * 22)))
    }

    private func elapsedTime(from date: Date) -> String {
        let elapsed = max(0, Int(date.timeIntervalSince(recordingStartedAt)))
        return String(format: "0:%02d", elapsed)
    }

    private func saveNote() {
        let value = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { return }
        recorder.clear()
        listening = false
        let note = store.createNote()
        store.updateNoteContent(id: note.id, title: "", content: value)
        text = ""
    }
}
