import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @EnvironmentObject private var player: AudioPlayerModel
    @State private var showImporter = false
    @State private var importingFolder = true

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                header
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial)
                ScrollView {
                    VStack(spacing: 20) {
                        artwork(height: min(250, max(100, geometry.size.height * 0.30)))
                        controls
                        playlist
                    }
                    .frame(maxWidth: 560)
                    .frame(maxWidth: .infinity)
                    .padding(20)
                }
            }
        }
        .background {
            LinearGradient(
                colors: [Color(red: 0.03, green: 0.04, blue: 0.12),
                         Color(red: 0.11, green: 0.02, blue: 0.22)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            ).ignoresSafeArea()
        }
        .preferredColorScheme(.dark)
        .fileImporter(
            isPresented: $showImporter,
            allowedContentTypes: importingFolder ? [.folder] : [.audio],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                guard let url = urls.first else { return }
                if importingFolder { player.chooseFolder(url) }
                else { player.openIncomingFile(url) }
            case .failure(let error):
                player.errorMessage = "Unable to open your selection: \(error.localizedDescription)"
            }
        }
        .alert("Music Player", isPresented: Binding(
            get: { player.errorMessage != nil },
            set: { if !$0 { player.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { player.errorMessage = nil }
        } message: {
            Text(player.errorMessage ?? "")
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            Menu {
                Button {
                    importingFolder = true
                    showImporter = true
                } label: {
                    Label("Choose folder", systemImage: "folder")
                }
                Button {
                    importingFolder = false
                    showImporter = true
                } label: {
                    Label("Open audio file", systemImage: "music.note")
                }
            } label: {
                Image(systemName: "line.3.horizontal")
                    .font(.title2)
                    .foregroundStyle(.cyan)
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel("Music menu")
            VStack(alignment: .leading, spacing: 3) {
                Text("INTERA")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .tracking(4)
                    .foregroundStyle(.cyan)
                Text("Music Player").font(.headline)
            }
            Spacer(minLength: 0)
        }
    }

    private func artwork(height: CGFloat) -> some View {
        VStack(spacing: 16) {
            Image("InteraLogo")
                .resizable()
                .scaledToFit()
                .padding(16)
                .frame(maxWidth: .infinity)
                .frame(height: height)
                .background(Color.white, in: RoundedRectangle(cornerRadius: 24))
                .accessibilityLabel("Intera Audit Solutions")
            VStack(spacing: 4) {
                Text(player.currentTrack?.title ?? "Choose your music folder")
                    .font(.title3.bold())
                    .multilineTextAlignment(.center)
                Text(player.folderName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }

    private var controls: some View {
        VStack(spacing: 10) {
            Slider(value: Binding(get: { player.progress }, set: { player.seek($0) }),
                   in: 0...max(player.duration, 1))
                .tint(.cyan)
                .disabled(player.duration == 0)
                .accessibilityLabel("Playback position")
            HStack {
                Text(format(player.progress))
                Spacer()
                Text(format(player.duration))
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            HStack(spacing: 28) {
                Button { player.previous() } label: {
                    Image(systemName: "backward.fill").frame(width: 44, height: 44)
                }.accessibilityLabel("Previous track")
                Button { player.togglePlay() } label: {
                    Image(systemName: player.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 64))
                }.accessibilityLabel(player.isPlaying ? "Pause" : "Play")
                Button { player.next() } label: {
                    Image(systemName: "forward.fill").frame(width: 44, height: 44)
                }.accessibilityLabel("Next track")
            }
            .foregroundStyle(.white)
            .disabled(player.tracks.isEmpty)
            HStack {
                Button { player.shuffle.toggle() } label: {
                    Image(systemName: "shuffle")
                        .foregroundStyle(player.shuffle ? .cyan : .secondary)
                        .frame(width: 44, height: 44)
                }.accessibilityLabel(player.shuffle ? "Shuffle on" : "Shuffle off")
                Spacer()
                Button { player.repeatTrack.toggle() } label: {
                    Image(systemName: "repeat")
                        .foregroundStyle(player.repeatTrack ? .cyan : .secondary)
                        .frame(width: 44, height: 44)
                }.accessibilityLabel(player.repeatTrack ? "Repeat on" : "Repeat off")
            }
        }
    }

    private var playlist: some View {
        LazyVStack(alignment: .leading, spacing: 10) {
            Text("PLAYLIST Â· \(player.tracks.count) tracks")
                .font(.caption.bold()).tracking(1.5).foregroundStyle(.secondary)
            if player.tracks.isEmpty {
                Text("Open the menu at the top left and choose a folder containing music.")
                    .font(.subheadline).foregroundStyle(.secondary)
            }
            ForEach(Array(player.tracks.enumerated()), id: \.element.id) { index, track in
                Button {
                    player.prepare(index: index)
                    player.play()
                } label: {
                    HStack {
                        Text(String(format: "%02d", index + 1))
                            .font(.caption.monospaced()).foregroundStyle(.secondary)
                            .frame(width: 28)
                        Text(track.title).lineLimit(2)
                        Spacer()
                        if index == player.currentIndex {
                            Image(systemName: player.isPlaying ? "waveform" : "pause")
                                .foregroundStyle(.cyan)
                        }
                    }
                    .frame(minHeight: 44)
                    .foregroundStyle(.white)
                }.buttonStyle(.plain)
            }
        }
    }

    private func format(_ seconds: Double) -> String {
        guard seconds.isFinite else { return "0:00" }
        return "\(Int(seconds) / 60):\(String(format: "%02d", Int(seconds) % 60))"
    }
}
