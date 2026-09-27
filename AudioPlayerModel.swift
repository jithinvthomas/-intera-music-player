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
    @Published var errorMessage: String?

    private var audio: AVAudioPlayer?
    private var timer: Timer?
    // Keep the selected folder/file accessible for the entire playlist lifetime.
    private var scopedURL: URL?
    private let extensions = ["mp3", "m4a", "wav", "aac", "flac", "aiff", "caf"]

    var currentTrack: Track? { tracks.indices.contains(currentIndex) ? tracks[currentIndex] : nil }

    func chooseFolder(_ url: URL) {
        let hasScope = url.startAccessingSecurityScopedResource()
        do {
            let urls = try FileManager.default.contentsOfDirectory(
                at: url, includingPropertiesForKeys: [.isRegularFileKey], options: [.skipsHiddenFiles]
            )
            let selected = try urls.filter {
                guard extensions.contains($0.pathExtension.lowercased()) else { return false }
                return try $0.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile == true
            }.sorted {
                $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending
            }.map(Track.init)
            replaceSelection(with: selected, url: url, hasScope: hasScope, name: url.lastPathComponent)
            if tracks.isEmpty {
                errorMessage = "No supported audio files were found in this folder. Choose the folder that contains your songs."
            } else {
                prepare(index: 0)
            }
        } catch {
            if hasScope { url.stopAccessingSecurityScopedResource() }
            errorMessage = "Unable to read this folder: \(error.localizedDescription)"
        }
    }

    func openIncomingFile(_ url: URL) {
        guard extensions.contains(url.pathExtension.lowercased()) else {
            errorMessage = "This audio file type is not supported."
            return
        }
        let hasScope = url.startAccessingSecurityScopedResource()
        replaceSelection(with: [Track(url: url)], url: url, hasScope: hasScope,
                         name: url.deletingLastPathComponent().lastPathComponent)
        prepare(index: 0)
        play()
    }

    private func replaceSelection(with selected: [Track], url: URL, hasScope: Bool, name: String) {
        pause()
        audio = nil
        scopedURL?.stopAccessingSecurityScopedResource()
        scopedURL = hasScope ? url : nil
        tracks = selected
        folderName = name
        currentIndex = 0
        progress = 0
        duration = 0
        errorMessage = nil
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }

    func prepare(index: Int) {
        guard tracks.indices.contains(index) else { return }
        pause()
        audio = nil
        duration = 0
        progress = 0
        currentIndex = index
        errorMessage = nil
        do {
            let prepared = try AVAudioPlayer(contentsOf: tracks[index].url)
            prepared.delegate = self
            guard prepared.prepareToPlay() else {
                errorMessage = "This song could not be prepared for playback."
                updateNowPlaying()
                return
            }
            audio = prepared
            duration = prepared.duration
        } catch {
            errorMessage = "Unable to play this song: \(error.localizedDescription). If it is stored in iCloud, download it in Files and try again."
        }
        updateNowPlaying()
    }

    func play() {
        guard let audio else { return }
        guard audio.play() else {
            isPlaying = false
            stopTimer()
            errorMessage = "Playback could not start. Please try another song."
            updateNowPlaying()
            return
        }
        isPlaying = true
        startTimer()
        updateNowPlaying()
    }

    func pause() { audio?.pause(); isPlaying = false; stopTimer(); updateNowPlaying() }
    func togglePlay() { isPlaying ? pause() : play() }

    func next() {
        guard !tracks.isEmpty else { return }
        let nextIndex = shuffle ? Int.random(in: 0..<tracks.count) : (currentIndex + 1) % tracks.count
        prepare(index: nextIndex)
        play()
    }

    func previous() {
        guard !tracks.isEmpty else { return }
        prepare(index: currentIndex == 0 ? tracks.count - 1 : currentIndex - 1)
        play()
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

    deinit {
        timer?.invalidate()
        scopedURL?.stopAccessingSecurityScopedResource()
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if repeatTrack { prepare(index: currentIndex); play() } else { next() }
    }

    private func updateNowPlaying() {
        guard let track = currentTrack else { return }
        MPNowPlayingInfoCenter.default().nowPlayingInfo = [
            MPMediaItemPropertyTitle: track.title,
            MPMediaItemPropertyAlbumTitle: "Intera Music",
            MPNowPlayingInfoPropertyElapsedPlaybackTime: progress,
            MPMediaItemPropertyPlaybackDuration: duration,
            MPNowPlayingInfoPropertyPlaybackRate: isPlaying ? 1.0 : 0.0
        ]
    }
}
