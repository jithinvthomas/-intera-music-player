import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @EnvironmentObject private var player: AudioPlayerModel
    @State private var showFolderPicker = false
    @State private var showFilePicker = false

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(red: 0.03, green: 0.04, blue: 0.12), Color(red: 0.11, green: 0.02, blue: 0.22)], startPoint: .topLeading, endPoint: .bottomTrailing).ignoresSafeArea()
            Circle().fill(.purple.opacity(0.22)).frame(width: 280).blur(radius: 50).offset(x: 150, y: -280)
            VStack(spacing: 0) {
                header
                artwork
                controls
                playlist
            }.padding(.horizontal, 20)
        }
        .preferredColorScheme(.dark)
        .fileImporter(isPresented: $showFolderPicker, allowedContentTypes: [.folder], allowsMultipleSelection: false) { result in if case .success(let urls) = result, let url = urls.first { player.chooseFolder(url) } }
        .fileImporter(isPresented: $showFilePicker, allowedContentTypes: [.audio], allowsMultipleSelection: false) { result in if case .success(let urls) = result, let url = urls.first { player.openIncomingFile(url) } }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) { Text("INTERA").font(.system(size: 13, weight: .bold, design: .rounded)).tracking(4).foregroundStyle(.cyan); Text("Music Player").font(.title2.bold()) }
            Spacer()
            Menu { Button("Open Folder") { showFolderPicker = true }; Button("Open Audio File") { showFilePicker = true } } label: { Image(systemName: "plus.circle.fill").font(.title).foregroundStyle(.cyan) }
        }.padding(.top, 12)
    }

    private var artwork: some View {
        VStack(spacing: 18) {
            ZStack { RoundedRectangle(cornerRadius: 32).fill(LinearGradient(colors: [.cyan.opacity(0.75), .purple.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing)); Image(systemName: "globe.americas.fill").font(.system(size: 104)).foregroundStyle(.white.opacity(0.86)).shadow(color: .cyan, radius: 22) }.frame(height: 250).padding(.top, 22)
            VStack(spacing: 4) { Text(player.currentTrack?.title ?? "Choose your music folder").font(.title3.bold()).lineLimit(1); Text(player.folderName).font(.subheadline).foregroundStyle(.secondary) }
        }
    }

    private var controls: some View {
        VStack(spacing: 10) {
            Slider(value: Binding(get: { player.progress }, set: { player.seek($0) }), in: 0...max(player.duration, 1)).tint(.cyan)
            HStack { Text(format(player.progress)); Spacer(); Text(format(player.duration)) }.font(.caption).foregroundStyle(.secondary)
            HStack(spacing: 34) { Button { player.previous() } label: { Image(systemName: "backward.fill") }; Button { player.togglePlay() } label: { Image(systemName: player.isPlaying ? "pause.circle.fill" : "play.circle.fill").font(.system(size: 64)) }; Button { player.next() } label: { Image(systemName: "forward.fill") } }.foregroundStyle(.white)
            HStack { Button { player.shuffle.toggle() } label: { Image(systemName: "shuffle").foregroundStyle(player.shuffle ? .cyan : .secondary) }; Spacer(); Button { player.repeatTrack.toggle() } label: { Image(systemName: "repeat").foregroundStyle(player.repeatTrack ? .cyan : .secondary) } }.padding(.horizontal, 12)
        }.padding(.top, 18)
    }

    private var playlist: some View {
        VStack(alignment: .leading, spacing: 10) { Text("PLAYLIST  •  \(player.tracks.count) tracks").font(.caption.bold()).tracking(1.5).foregroundStyle(.secondary); ScrollView { ForEach(Array(player.tracks.enumerated()), id: \.element.id) { index, track in Button { player.prepare(index: index); player.play() } label: { HStack { Text(String(format: "%02d", index + 1)).font(.caption.monospaced()).foregroundStyle(.secondary).frame(width: 28); Text(track.title).lineLimit(1); Spacer(); if index == player.currentIndex { Image(systemName: player.isPlaying ? "waveform" : "pause").foregroundStyle(.cyan) } }.padding(.vertical, 7).foregroundStyle(.white) }.buttonStyle(.plain) } }.frame(maxHeight: 180) }.padding(.top, 22)
    }

    private func format(_ seconds: Double) -> String { guard seconds.isFinite else { return "0:00" }; return "\(Int(seconds) / 60):\(String(format: "%02d", Int(seconds) % 60))" }
}
