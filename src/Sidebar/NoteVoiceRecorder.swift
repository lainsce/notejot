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
        transcript = ""
        samples = NoteSpeechSamples()
        errorDescription = nil
        acceptsTranscription = true
        guard case .granted = AVAudioApplication.shared.recordPermission else {
            AVAudioApplication.requestRecordPermission { [weak self] granted in
                guard granted else { return }
                Task { @MainActor in self?.start() }
            }
            return
        }
        guard SFSpeechRecognizer.authorizationStatus() == .authorized else {
            SFSpeechRecognizer.requestAuthorization { [weak self] status in
                guard status == .authorized else { return }
                Task { @MainActor in self?.start() }
            }
            return
        }
        guard let recognizer, recognizer.isAvailable else {
            errorDescription = "Speech recognition is unavailable."
            return
        }
        let input = engine.inputNode
        let format = input.inputFormat(forBus: 0)
        guard format.sampleRate > 0, format.channelCount > 0 else {
            errorDescription = "No microphone input is available."
            return
        }
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        let requestBox = NoteSpeechRequestBox(request)
        let sampleBox = samples
        self.request = request
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
        input.removeTap(onBus: 0)
        do {
            try input.installAudioTap(onBus: 0, bufferSize: 512, format: format) { buffer, _ in
                if let copy = Self.mutableBuffer(copying: buffer) {
                    requestBox.request.append(copy)
                    sampleBox.append(copy)
                }
                guard case .float(let samples) = buffer.channelData(0) else { return }
                let count = Int(buffer.frameLength)
                guard count > 0 else { return }
                var energy: Float = 0
                for index in 0..<count { energy += abs(samples[index]) }
                let level = min(1, CGFloat(energy / Float(count)) * 10)
                Task { @MainActor [weak self = self] in
                    self?.bass = max(0.12, level * 0.8)
                    self?.mid = max(0.12, level)
                    self?.treble = max(0.12, level * 0.65)
                }
            }
            engine.prepare()
            try engine.start()
            isRecording = true
        } catch {
            stop()
        }
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
        guard let copy = AVAudioPCMBuffer(
            pcmFormat: buffer.format,
            frameCapacity: AVAudioFrameCount(buffer.frameLength)
        ), let destination = copy.floatChannelData else { return nil }
        copy.frameLength = AVAudioFrameCount(buffer.frameLength)
        for index in 0..<Int(buffer.format.channelCount) {
            guard case .float(let values) = buffer.channelData(index) else { continue }
            let samples = values.withUnsafeBufferPointer { Array($0) }
            samples.withUnsafeBufferPointer { pointer in
                guard let source = pointer.baseAddress else { return }
                memcpy(destination[index], source, samples.count * MemoryLayout<Float>.size)
            }
        }
        return copy
    }

}
