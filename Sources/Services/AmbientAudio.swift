import AVFoundation
import SwiftUI

/// Original procedural ambience: no recordings, assets or network access.
@MainActor final class AmbientAudio: ObservableObject {
    @Published var sound = "Off" { didSet { play() } }
    @Published var volume: Double = 0.25 { didSet { player?.volume = Float(volume) } }
    @Published var error: String?
    private var player: AVAudioPlayer?
    func play() {
        player?.stop(); player = nil
        guard sound != "Off" else { return }
        let rate = 22050
        let count = rate * 12
        var samples = [Int16](); samples.reserveCapacity(count)
        var low = 0.0; var seed: UInt64 = 71423
        for i in 0..<count {
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
            samples.append(Int16(max(-1, min(1, wave * fade)) * 24000))
        }
        var data = Data()
        func ascii(_ value: String) { data.append(contentsOf: value.utf8) }
        func u32(_ value: UInt32) { var v = value.littleEndian; withUnsafeBytes(of: &v) { data.append(contentsOf: $0) } }
        func u16(_ value: UInt16) { var v = value.littleEndian; withUnsafeBytes(of: &v) { data.append(contentsOf: $0) } }
        ascii("RIFF"); u32(UInt32(36 + samples.count * 2)); ascii("WAVEfmt "); u32(16); u16(1); u16(1); u32(UInt32(rate)); u32(UInt32(rate * 2)); u16(2); u16(16); ascii("data"); u32(UInt32(samples.count * 2))
        for sample in samples { u16(UInt16(bitPattern: sample)) }
        do { player = try AVAudioPlayer(data: data); player?.numberOfLoops = -1; player?.volume = Float(volume); player?.play() }
        catch { self.error = error.localizedDescription }
    }
}
struct AmbientControls: View {
    @Environment(\.studyTheme) private var appTheme
    @ObservedObject var audio: AmbientAudio
    var body: some View {
        HStack {
            Image(systemName: "waveform").foregroundStyle(appTheme.palette.textSecondary)
            StudyDropdown(title: "Ambiente", options: [("Off", "Silenzio"), ("Pioggia", "Pioggia"), ("Vento", "Vento"), ("Camino", "Camino")], selection: $audio.sound).frame(width: 170)
            StudyVolumeSlider(value: $audio.volume).frame(width: 100)

        }.help("Suoni sintetizzati originali, senza registrazioni esterne")
    }
}
