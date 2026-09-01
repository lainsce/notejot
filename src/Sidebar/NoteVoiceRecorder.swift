import AVFoundation
import Combine
import Speech

private final class NoteSpeechRequestBox: @unchecked Sendable {
    nonisolated(unsafe) let request: SFSpeechAudioBufferRecognitionRequest
    init(_ request: SFSpeechAudioBufferRecognitionRequest) { self.request = request }
}

@MainActor
final class NoteVoiceRecorder: ObservableObject {
    @Published private(set) var transcript = ""
    @Published private(set) var isRecording = false
    @Published private(set) var bass: CGFloat = 0.18
    @Published private(set) var mid: CGFloat = 0.28
    @Published private(set) var treble: CGFloat = 0.20
    @Published private(set) var errorDescription: String?

    private var engine = AVAudioEngine()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    // Follow the user's system language for live partials; WhisperKit performs
    // language detection for the final transcript.
    private let recognizer = SFSpeechRecognizer(locale: .current)
    private var acceptsTranscription = false
    private var samples = NoteSpeechSamples()

    func start() {
        guard !isRecording else { return }
        prepareForRecording()
        guard let context = recordingContext() else { return }
        self.request = context.request
        configureRecognition(using: context.recognizer, request: context.request)
        do {
            try installAudioTap(
                on: context.input,
                format: context.format,
                requestBox: context.requestBox,
                sampleBox: context.sampleBox
            )
            engine.prepare()
            try engine.start()
            isRecording = true
        } catch {
            stop()
        }
    }

    private struct RecordingContext {
        let recognizer: SFSpeechRecognizer
        let input: AVAudioInputNode
        let format: AVAudioFormat
        let request: SFSpeechAudioBufferRecognitionRequest
        let requestBox: NoteSpeechRequestBox
        let sampleBox: NoteSpeechSamples
    }

    private func recordingContext() -> RecordingContext? {
        guard permissionsReady(), let recognizer = availableRecognizer() else { return nil }
        guard let input = availableInput() else { return nil }
        let format = input.inputFormat(forBus: 0)
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        return RecordingContext(
            recognizer: recognizer,
            input: input,
            format: format,
            request: request,
            requestBox: NoteSpeechRequestBox(request),
            sampleBox: samples
        )
    }

    private func permissionsReady() -> Bool {
        requestRecordPermissionIfNeeded() && requestSpeechAuthorizationIfNeeded()
    }

    private func availableRecognizer() -> SFSpeechRecognizer? {
        guard let recognizer, recognizer.isAvailable else {
            errorDescription = "Speech recognition is unavailable."
            return nil
        }
        return recognizer
    }

    private func availableInput() -> AVAudioInputNode? {
        let input = engine.inputNode
        let format = input.inputFormat(forBus: 0)
        guard format.sampleRate > 0, format.channelCount > 0 else {
            errorDescription = "No microphone input is available."
            return nil
        }
        return input
    }

    private func prepareForRecording() {
        transcript = ""
        samples = NoteSpeechSamples()
        errorDescription = nil
        acceptsTranscription = true
    }

    private func requestRecordPermissionIfNeeded() -> Bool {
        guard case .granted = AVAudioApplication.shared.recordPermission else {
            AVAudioApplication.requestRecordPermission { [weak self] granted in
                guard granted else { return }
                Task { @MainActor in self?.start() }
            }
            return false
        }
        return true
    }

    private func requestSpeechAuthorizationIfNeeded() -> Bool {
        guard SFSpeechRecognizer.authorizationStatus() == .authorized else {
            SFSpeechRecognizer.requestAuthorization { [weak self] status in
                guard status == .authorized else { return }
                Task { @MainActor in self?.start() }
            }
            return false
        }
        return true
    }

    private func configureRecognition(
        using recognizer: SFSpeechRecognizer,
        request: SFSpeechAudioBufferRecognitionRequest
    ) {
        task?.cancel()
        task = recognizer.recognitionTask(with: request) { [weak self] result, error in
            if let error {
                Task { @MainActor [weak self] in
                    self?.errorDescription = error.localizedDescription
                }
            }
            guard let result else { return }
            let value = result.bestTranscription.formattedString
            Task { @MainActor [weak self] in
                guard let self, self.acceptsTranscription, !value.isEmpty else { return }
                self.transcript = value
            }
        }
    }

    private func installAudioTap(
        on input: AVAudioInputNode,
        format: AVAudioFormat,
        requestBox: NoteSpeechRequestBox,
        sampleBox: NoteSpeechSamples
    ) throws {
        input.removeTap(onBus: 0)
        try input.installAudioTap(onBus: 0, bufferSize: 512, format: format) { buffer, _ in
            Self.processAudioBuffer(buffer, requestBox: requestBox, sampleBox: sampleBox) { [weak recorder = self] level in
                Task { @MainActor [weak recorder] in
                    recorder?.bass = max(0.12, level * 0.8)
                    recorder?.mid = max(0.12, level)
                    recorder?.treble = max(0.12, level * 0.65)
                }
            }
        }
    }

    private nonisolated static func processAudioBuffer(
        _ buffer: AVReadOnlyAudioPCMBuffer,
        requestBox: NoteSpeechRequestBox,
        sampleBox: NoteSpeechSamples,
        update: @escaping (CGFloat) -> Void
    ) {
        appendCopiedBuffer(buffer, requestBox: requestBox, sampleBox: sampleBox)
        guard let level = audioLevel(from: buffer) else { return }
        update(level)
    }

    private nonisolated static func appendCopiedBuffer(
        _ buffer: AVReadOnlyAudioPCMBuffer,
        requestBox: NoteSpeechRequestBox,
        sampleBox: NoteSpeechSamples
    ) {
        guard let copy = mutableBuffer(copying: buffer) else { return }
        requestBox.request.append(copy)
        sampleBox.append(copy)
    }

    private nonisolated static func audioLevel(from buffer: AVReadOnlyAudioPCMBuffer) -> CGFloat? {
        guard case .float(let samples) = buffer.channelData(0) else { return nil }
        let count = Int(buffer.frameLength)
        guard count > 0 else { return nil }
        let energy = (0..<count).reduce(Float.zero) { $0 + abs(samples[$1]) }
        return min(1, CGFloat(energy / Float(count)) * 10)
    }

    func stop() {
        let capturedSamples = samples.snapshot()
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        request?.endAudio()
        request = nil
        isRecording = false
        engine = AVAudioEngine()
        bass = 0.18
        mid = 0.28
        treble = 0.20

        guard !capturedSamples.isEmpty else { return }
        Task { [weak self] in
            guard let value = await NoteWhisperTranscriber.shared.transcribe(samples: capturedSamples) else { return }
            await MainActor.run {
                guard let self, self.acceptsTranscription, !value.isEmpty else { return }
                self.transcript = value
            }
        }
    }

    func clear() {
        acceptsTranscription = false
        stop()
        transcript = ""
        errorDescription = nil
    }

    private nonisolated static func mutableBuffer(copying buffer: AVReadOnlyAudioPCMBuffer) -> AVAudioPCMBuffer? {
        AVAudioPCMBuffer(copying: buffer)
    }

}
