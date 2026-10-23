import AVFoundation
import SwiftUI

/// Original procedural ambience: no recordings, assets or network access.
@MainActor final class AmbientAudio: ObservableObject {
    @Published var sound = "Off" { didSet { play() } }
    @Published var volume: Double = 0.25 { didSet { player?.volume = Float(volume) } }
    @Published var error: String?
    private var player: AVAudioPlayer?
    private var generation: Task<Void, Never>?
    private var requestID = UUID()
    func play() {
        generation?.cancel()
        requestID = UUID()
        player?.stop(); player = nil
        guard sound != "Off" else { generation = nil; return }
        let request = requestID
        let sound = sound
        generation = Task { [weak self] in
            guard !Task.isCancelled else { return }
            // PCM synthesis is CPU work; keep it off the UI actor. Cancel superseded
            // requests so rapid changes never install an obsolete sound afterwards.
            let worker = Task.detached(priority: .userInitiated) { try AmbientWaveform.makeData(sound: sound) }
            do {
                let data = try await withTaskCancellationHandler(operation: { try await worker.value }, onCancel: { worker.cancel() })
                guard !Task.isCancelled, let self, self.requestID == request else { return }
                self.player = try AVAudioPlayer(data: data)
                self.player?.numberOfLoops = -1
                self.player?.volume = Float(self.volume)
                self.player?.play()
            } catch is CancellationError {
                // Changing sound or leaving the store cancels work, not an app error.
            } catch {
                guard !Task.isCancelled, let self, self.requestID == request else { return }
                self.error = L10n.errorMessage(error)
            }
        }
    }
    deinit { generation?.cancel() }
}

/// Pure, deterministic WAV generation. Sound IDs deliberately stay untranslated.
/// Stream samples directly into the preallocated buffer instead of retaining a
/// second sample array. Cancellation is checked in batches, away from AppKit.
enum AmbientWaveform {
    static func makeData(sound: String) throws -> Data {
        let rate = 22050
        let count = rate * 12
        var data = Data()
        data.reserveCapacity(44 + count * 2)
        func ascii(_ value: String) { data.append(contentsOf: value.utf8) }
        func u32(_ value: UInt32) { var v = value.littleEndian; withUnsafeBytes(of: &v) { data.append(contentsOf: $0) } }
        func u16(_ value: UInt16) { var v = value.littleEndian; withUnsafeBytes(of: &v) { data.append(contentsOf: $0) } }
        ascii("RIFF"); u32(UInt32(36 + count * 2)); ascii("WAVEfmt "); u32(16); u16(1); u16(1)
        u32(UInt32(rate)); u32(UInt32(rate * 2)); u16(2); u16(16); ascii("data"); u32(UInt32(count * 2))
        var low = 0.0
        var seed: UInt64 = 71423
        for i in 0..<count {
            if i % 4096 == 0 { try Task.checkCancellation() }
            seed = seed &* 6364136223846793005 &+ 1
            let noise = Double(seed >> 33) / Double(UInt32.max >> 1) * 2 - 1
            low = low * 0.98 + noise * 0.02
            let t = Double(i) / Double(rate)
            let wave: Double
            switch sound {
            case "Pioggia": wave = noise * 0.22 + low * 0.7
            case "Vento": wave = low * (1.8 + sin(t * .pi / 6) * 0.6)
            default: wave = low * 1.3 + (abs(noise) > 0.998 ? noise * 0.3 : 0)
            }
            let fade = min(1, min(Double(i) / 1000, Double(count - i - 1) / 1000))
            let sample = Int16(max(-1, min(1, wave * fade)) * 24000)
            u16(UInt16(bitPattern: sample))
        }
        return data
    }
}
struct AmbientControls: View {
    @ObservedObject private var appLocalization = AppLocalization.shared
    @Environment(\.studyTheme) private var appTheme
    @ObservedObject var audio: AmbientAudio
    var body: some View {
        HStack {
            Image(systemName: "waveform").foregroundStyle(appTheme.palette.textSecondary)
            StudyDropdown(title: L10n.tr("Ambiente"), options: [("Off", L10n.tr("Silenzio")), ("Pioggia", L10n.tr("Pioggia")), ("Vento", L10n.tr("Vento")), ("Camino", L10n.tr("Camino"))], selection: $audio.sound).frame(width: 170)
            StudyVolumeSlider(value: $audio.volume).frame(width: 100)

        }.help(L10n.tr("Suoni sintetizzati originali, senza registrazioni esterne"))
    }
}
