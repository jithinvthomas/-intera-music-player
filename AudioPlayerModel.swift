import Foundation
import AVFoundation
import MediaPlayer

struct Track: Identifiable, Equatable {
    let id = UUID()
    let url: URL
    var title: String { url.deletingPathExtension().lastPathComponent }
}

@MainActor
final class AudioPlayerModel: NSObject, ObservableObject, AVAudioPlayerDelegate {
    @Published var tracks: [Track] = []
    @Published var currentIndex = 0
    @Published var isPlaying = false
    @Published var progress: Double = 0
    @Published var duration: Double = 0
    @Published var folderName = "No folder selected"
    @Published var shuffle = false
    @Published var repeatTrack = false

    private var audio: AVAudioPlayer?
    private var timer: Timer?
    private let extensions = ["mp3", "m4a", "wav", "aac", "flac", "aiff", "caf"]

    var currentTrack: Track? { tracks.indices.contains(currentIndex) ? tracks[currentIndex] : nil }

    func chooseFolder(_ url: URL) {
        guard url.startAccessingSecurityScopedResource() else { return }
        defer { url.stopAccessingSecurityScopedResource() }
        let urls = (try? FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: [.isRegularFileKey], options: [.skipsHiddenFiles])) ?? []
        tracks = urls.filter { extensions.contains($0.pathExtension.lowercased()) }.sorted { $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending }.map(Track.init)
        folderName = url.lastPathComponent
        currentIndex = 0
        if !tracks.isEmpty { prepare(index: 0) }
    }

    func openIncomingFile(_ url: URL) {
        guard extensions.contains(url.pathExtension.lowercased()) else { return }
        tracks = [Track(url: url)]
        currentIndex = 0
        folderName = url.deletingLastPathComponent().lastPathComponent
        prepare(index: 0)
        play()
    }

    func prepare(index: Int) {
        guard tracks.indices.contains(index) else { return }
        currentIndex = index
        audio = try? AVAudioPlayer(contentsOf: tracks[index].url)
        audio?.delegate = self
        audio?.prepareToPlay()
        duration = audio?.duration ?? 0
        progress = 0
        updateNowPlaying()
    }

    func play() {
        guard audio != nil else { return }
        audio?.play(); isPlaying = true; startTimer(); updateNowPlaying()
    }

    func pause() { audio?.pause(); isPlaying = false; stopTimer(); updateNowPlaying() }

    func togglePlay() { isPlaying ? pause() : play() }

    func next() {
        guard !tracks.isEmpty else { return }
        let nextIndex = shuffle ? Int.random(in: 0..<tracks.count) : (currentIndex + 1) % tracks.count
        prepare(index: nextIndex); play()
    }

    func previous() {
        guard !tracks.isEmpty else { return }
        prepare(index: currentIndex == 0 ? tracks.count - 1 : currentIndex - 1); play()
    }

    func seek(_ value: Double) { audio?.currentTime = value; progress = value; updateNowPlaying() }

    private func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self, let audio = self.audio else { return }
            self.progress = audio.currentTime
        }
    }
    private func stopTimer() { timer?.invalidate(); timer = nil }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if repeatTrack { prepare(index: currentIndex); play() } else { next() }
    }

    private func updateNowPlaying() {
        guard let track = currentTrack else { return }
        MPNowPlayingInfoCenter.default().nowPlayingInfo = [MPMediaItemPropertyTitle: track.title, MPMediaItemPropertyAlbumTitle: "Intera Music", MPNowPlayingInfoPropertyElapsedPlaybackTime: progress, MPMediaItemPropertyPlaybackDuration: duration, MPNowPlayingInfoPropertyPlaybackRate: isPlaying ? 1.0 : 0.0]
    }
}
