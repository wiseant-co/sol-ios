import AVFoundation

/// Captures the mic and produces 16 kHz mono 16-bit PCM WAV — the format the proxy expects.
/// Used by the host app's dictate screen and by the keyboard extension (Full Access required for the
/// mic there). Streams samples into a buffer and converts on stop to keep memory low (the keyboard
/// extension has a tight limit).
public final class AudioRecorder {
    private let engine = AVAudioEngine()
    private var converter: AVAudioConverter?
    private var samples: [Int16] = []
    private let targetFormat = AVAudioFormat(commonFormat: .pcmFormatInt16, sampleRate: 16000,
                                             channels: 1, interleaved: true)!

    public init() {}

    /// Ask for mic permission (the host app should call this during onboarding).
    public static func requestPermission() async -> Bool {
        await withCheckedContinuation { cont in
            AVAudioApplication.requestRecordPermission { granted in cont.resume(returning: granted) }
        }
    }

    public func start() throws {
        samples.removeAll(keepingCapacity: true)

        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.record, mode: .measurement, options: [.duckOthers])
        try session.setActive(true)

        let input = engine.inputNode
        let inputFormat = input.outputFormat(forBus: 0)
        converter = AVAudioConverter(from: inputFormat, to: targetFormat)

        input.installTap(onBus: 0, bufferSize: 2048, format: inputFormat) { [weak self] buffer, _ in
            self?.ingest(buffer)
        }
        try engine.start()
    }

    /// Stop and return the recorded audio as a 16 kHz mono WAV.
    public func stop() -> Data {
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        try? AVAudioSession.sharedInstance().setActive(false)
        return WAV.encode(samples: samples, sampleRate: 16000)
    }

    private func ingest(_ buffer: AVAudioPCMBuffer) {
        guard let converter else { return }
        let ratio = targetFormat.sampleRate / buffer.format.sampleRate
        let capacity = AVAudioFrameCount(Double(buffer.frameLength) * ratio) + 1
        guard let out = AVAudioPCMBuffer(pcmFormat: targetFormat, frameCapacity: capacity) else { return }

        var fed = false
        var error: NSError?
        converter.convert(to: out, error: &error) { _, status in
            if fed { status.pointee = .noDataNow; return nil }
            fed = true
            status.pointee = .haveData
            return buffer
        }
        if let ch = out.int16ChannelData, out.frameLength > 0 {
            samples.append(contentsOf: UnsafeBufferPointer(start: ch[0], count: Int(out.frameLength)))
        }
    }
}
