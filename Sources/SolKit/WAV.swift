import Foundation

/// Minimal 16-bit PCM WAV writer (mono). Wraps captured Int16 samples with a RIFF header so the
/// proxy/Gemini receive a standard WAV. Mirrors SolCore's WAV encoder.
public enum WAV {
    public static func encode(samples: [Int16], sampleRate: Int = 16000) -> Data {
        let channels = 1
        let bitsPerSample = 16
        let byteRate = sampleRate * channels * bitsPerSample / 8
        let blockAlign = channels * bitsPerSample / 8
        let dataSize = samples.count * MemoryLayout<Int16>.size

        var d = Data()
        func str(_ s: String) { d.append(s.data(using: .ascii)!) }
        func u32(_ v: UInt32) { var x = v.littleEndian; d.append(Data(bytes: &x, count: 4)) }
        func u16(_ v: UInt16) { var x = v.littleEndian; d.append(Data(bytes: &x, count: 2)) }

        str("RIFF"); u32(UInt32(36 + dataSize)); str("WAVE")
        str("fmt "); u32(16); u16(1)                       // PCM
        u16(UInt16(channels)); u32(UInt32(sampleRate))
        u32(UInt32(byteRate)); u16(UInt16(blockAlign)); u16(UInt16(bitsPerSample))
        str("data"); u32(UInt32(dataSize))
        samples.withUnsafeBytes { d.append(contentsOf: $0) }
        return d
    }
}
