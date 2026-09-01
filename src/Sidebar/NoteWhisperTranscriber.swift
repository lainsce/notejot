import Foundation
import AVFoundation
@preconcurrency import WhisperKit

/// Local Whisper transcription shared by the voice composer. The model is downloaded
/// and cached by WhisperKit on first use; callers can continue using Apple Speech as
/// a live fallback while this finishes.
final class NoteWhisperTranscriber: @unchecked Sendable {
    static let shared = NoteWhisperTranscriber()

    private nonisolated(unsafe) var whisper: WhisperKit?
    func transcribe(samples: [Float]) async -> String? {
        guard samples.count > 3200 else { return nil }
        do {
            let whisper = try await instance()
            return await decode(samples, with: whisper)
        } catch {
            return nil
        }
    }

    private nonisolated func instance() async throws -> WhisperKit {
        if whisper == nil { whisper = try await WhisperKit(WhisperKitConfig(model: "base")) }
        guard let whisper else { throw TranscriptionError.unavailable }
        return whisper
    }

    private nonisolated func decode(_ samples: [Float], with whisper: WhisperKit) async -> String? {
        // Do not use WhisperKit's English prefill: detect the spoken language
        // from the recording so Brazilian Portuguese is transcribed naturally.
        let options = DecodingOptions(usePrefillPrompt: false, detectLanguage: true)
        let results = await whisper.transcribe(audioArrays: [samples], decodeOptions: options)
        guard let text = results.first??.map(\.text).joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines) else { return nil }
        return text.isEmpty ? nil : text
    }

    private enum TranscriptionError: Error { case unavailable }
}

final class NoteSpeechSamples: @unchecked Sendable {
    private let lock = NSLock()
    private nonisolated(unsafe) var values: [Float] = []
    private nonisolated(unsafe) var sourceSampleRate = Double(WhisperKit.sampleRate)

    nonisolated func append(_ buffer: AVAudioPCMBuffer) {
        let count = Int(buffer.frameLength)
        guard count > 0 else { return }
        lock.lock()
        appendSamples(buffer, count: count, sampleRate: buffer.format.sampleRate)
        lock.unlock()
    }

    private nonisolated func appendSamples(
        _ buffer: AVAudioPCMBuffer,
        count: Int,
        sampleRate: Double
    ) {
        guard case .float(let channel) = buffer.channelData(0) else { return }
        updateSourceSampleRate(sampleRate)
        values.append(contentsOf: (0..<count).map { channel[$0] })
    }

    private nonisolated func updateSourceSampleRate(_ sampleRate: Double) {
        guard sourceSampleRate == Double(WhisperKit.sampleRate) else { return }
        sourceSampleRate = sampleRate
    }

    nonisolated func snapshot() -> [Float] {
        lock.lock(); defer { lock.unlock() }
        guard sourceSampleRate > 0, sourceSampleRate != Double(WhisperKit.sampleRate), values.count > 1 else { return values }
        let outputCount = max(1, Int(Double(values.count) * Double(WhisperKit.sampleRate) / sourceSampleRate))
        return (0..<outputCount).map { index in
            let position = Double(index) * sourceSampleRate / Double(WhisperKit.sampleRate)
            let lower = min(values.count - 1, Int(position))
            let upper = min(values.count - 1, lower + 1)
            let fraction = Float(position - Double(lower))
            return values[lower] + (values[upper] - values[lower]) * fraction
        }
    }
}
