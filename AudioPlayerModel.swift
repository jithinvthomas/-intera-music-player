import Foundation
import AVFoundation
import MediaPlayer
import UIKit

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
    @Published private(set) var currentArtwork: UIImage?

    private var audio: AVAudioPlayer?
    private var timer: Timer?
    private var artworkTask: Task<Void, Never>?
    // Keep the selected folder/file accessible for the entire playlist lifetime.
    private var scopedURL: URL?
    private let extensions = ["mp3", "m4a", "wav", "aac", "flac", "aiff", "caf"]


    private let defaults: UserDefaults
    private let folderBookmarkKey = "lastMusicFolderBookmark"
    private var didRestoreFolder = false
    private var isInterrupted = false
    private var resumeAfterInterruption = false

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(handleInterruption(_:)),
            name: AVAudioSession.interruptionNotification, object: AVAudioSession.sharedInstance())
        NotificationCenter.default.addObserver(self, selector: #selector(handleRouteChange(_:)),
            name: AVAudioSession.routeChangeNotification, object: AVAudioSession.sharedInstance())
    }

    func restoreLastFolder() {
        guard !didRestoreFolder else { return }
        didRestoreFolder = true
        // An incoming file may have opened before the first view appeared.
        guard tracks.isEmpty, let data = defaults.data(forKey: folderBookmarkKey) else { return }
        do {
            var stale = false
            let url = try URL(resolvingBookmarkData: data, options: [],
                              relativeTo: nil, bookmarkDataIsStale: &stale)
            // Successful selection renews the bookmark, including stale bookmarks.
            chooseFolder(url)
        } catch {
            errorMessage = "Your saved folder could not be reopened. Choose it again from the menu."
        }
    }

    private func rememberFolder(_ url: URL) {
        do {
            let data = try url.bookmarkData(options: .minimalBookmark,
                                           includingResourceValuesForKeys: nil, relativeTo: nil)
            defaults.set(data, forKey: folderBookmarkKey)
        } catch {
            defaults.removeObject(forKey: folderBookmarkKey)
            errorMessage = "This folder is open, but its access could not be saved. Choose it again next time."
        }
    }

    @objc private func handleInterruption(_ notification: Notification) {
        guard let rawType = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: rawType) else { return }
        switch type {
        case .began:
            guard !isInterrupted else { return }
            let wasPlaying = isPlaying
            pause()
            isInterrupted = true
            resumeAfterInterruption = wasPlaying
        case .ended:
            guard isInterrupted else { return }
            let rawOptions = notification.userInfo?[AVAudioSessionInterruptionOptionKey] as? UInt ?? 0
            let shouldResume = resumeAfterInterruption &&
                AVAudioSession.InterruptionOptions(rawValue: rawOptions).contains(.shouldResume)
            isInterrupted = false
            resumeAfterInterruption = false
            if shouldResume { play() }
        @unknown default:
            break
        }
    }

    @objc nonisolated private func handleRouteChange(_ notification: Notification) {
        guard let reason = notification.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt,
              reason == AVAudioSession.RouteChangeReason.oldDeviceUnavailable.rawValue else { return }
        // Route notifications may arrive on a background thread.
        Task { @MainActor [weak self] in self?.pause() }
    }

    var currentTrack: Track? { tracks.indices.contains(currentIndex) ? tracks[currentIndex] : nil }

    func chooseFolder(_ url: URL) {
        let hasScope = url.startAccessingSecurityScopedResource()
        do {
            let values = try url.resourceValues(forKeys: [.isDirectoryKey])
            guard values.isDirectory == true else { throw CocoaError(.fileReadUnknown) }
            var scanError: Error?
            guard let enumerator = FileManager.default.enumerator(
                at: url,
                includingPropertiesForKeys: [.isRegularFileKey, .isSymbolicLinkKey],
                options: [.skipsHiddenFiles, .skipsPackageDescendants],
                errorHandler: { _, error in
                    scanError = error
                    return false
                }
            ) else { throw CocoaError(.fileReadUnknown) }
            var urls: [URL] = []
            for case let fileURL as URL in enumerator {
                guard extensions.contains(fileURL.pathExtension.lowercased()) else { continue }
                let values = try fileURL.resourceValues(forKeys: [.isRegularFileKey, .isSymbolicLinkKey])
                if values.isRegularFile == true && values.isSymbolicLink != true {
                    urls.append(fileURL)
                }
            }
            if let scanError { throw scanError }
            let selected = urls.sorted {
                let order = $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent)
                return order == .orderedSame ? $0.path < $1.path : order == .orderedAscending
            }.map(Track.init)
            replaceSelection(with: selected, url: url, hasScope: hasScope, name: url.lastPathComponent)
            if tracks.isEmpty {
                errorMessage = "No supported audio files were found in this folder or its subfolders. Choose the folder that contains your songs."
            } else {
                prepare(index: 0)
            }
            rememberFolder(url)
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
        artworkTask?.cancel()
        currentArtwork = nil
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
        artworkTask?.cancel()
        currentArtwork = nil
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
            loadArtwork(for: tracks[index])
        } catch {
            errorMessage = "Unable to play this song: \(error.localizedDescription). If it is stored in iCloud, download it in Files and try again."
        }
        updateNowPlaying()
    }

    static func embeddedArtwork(at url: URL) async -> UIImage? {
        do {
            let metadata = try await AVURLAsset(url: url).load(.commonMetadata)
            let artworkItems = AVMetadataItem.metadataItems(
                from: metadata, filteredByIdentifier: .commonIdentifierArtwork
            )
            for item in artworkItems {
                try Task.checkCancellation()
                if let data = try await item.load(.dataValue), let image = UIImage(data: data) {
                    return image
                }
            }
        } catch {
            // Artwork is optional; a missing or unreadable image must not stop music.
        }
        return nil
    }

    private func loadArtwork(for track: Track) {
        artworkTask = Task { [weak self] in
            let image = await Self.embeddedArtwork(at: track.url)
            guard !Task.isCancelled, let self, self.currentTrack?.id == track.id else { return }
            self.currentArtwork = image
            self.updateNowPlaying()
        }
    }

    func play() {
        guard !isInterrupted, let audio else { return }
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default,
                                    options: [.allowAirPlay, .allowBluetoothA2DP])
            try session.setActive(true)
        } catch {
            errorMessage = "Audio is unavailable: \(error.localizedDescription)"
            isPlaying = false
            stopTimer()
            updateNowPlaying()
            return
        }
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

    func pause() {
        resumeAfterInterruption = false
        audio?.pause()
        if let audio { progress = audio.currentTime }
        isPlaying = false
        stopTimer()
        updateNowPlaying()
    }
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
        NotificationCenter.default.removeObserver(self)
        artworkTask?.cancel()
        timer?.invalidate()
        scopedURL?.stopAccessingSecurityScopedResource()
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if repeatTrack { prepare(index: currentIndex); play() } else { next() }
    }

    private func updateNowPlaying() {
        guard let track = currentTrack else { return }
        var info: [String: Any] = [
            MPMediaItemPropertyTitle: track.title,
            MPMediaItemPropertyAlbumTitle: "Jiza",
            MPNowPlayingInfoPropertyElapsedPlaybackTime: progress,
            MPMediaItemPropertyPlaybackDuration: duration,
            MPNowPlayingInfoPropertyPlaybackRate: isPlaying ? 1.0 : 0.0
        ]
        if let image = currentArtwork {
            info[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
        }
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }
}
