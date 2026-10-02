import SwiftUI
import AVKit

struct VideoPlayerView: View {
    @ObservedObject var video: VideoPlayerModel

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(video.title).font(.headline).lineLimit(1)
                Spacer()
                Button("Done") { video.close() }
                    .frame(minWidth: 44, minHeight: 44)
                    .accessibilityLabel("Close video")
            }
            .padding(.horizontal)
            ZStack {
                Color.black
                if let error = video.errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle").font(.largeTitle)
                        Text(error).multilineTextAlignment(.center)
                        Button("Back to music") { video.close() }.buttonStyle(.bordered)
                    }.padding(24)
                } else if video.isLoading {
                    ProgressView("Opening video…").tint(.white)
                } else {
                    NativeVideoPlayer(player: video.player)
                }
            }
        }
        .foregroundStyle(.white)
        .background(.black)
        .preferredColorScheme(.dark)
    }
}

private struct NativeVideoPlayer: UIViewControllerRepresentable {
    let player: AVPlayer

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.player = player
        // PiP needs explicit app-restoration behavior; add it in the next slice.
        controller.allowsPictureInPicturePlayback = false
        return controller
    }

    func updateUIViewController(_ controller: AVPlayerViewController, context: Context) {
        controller.player = player
    }

    static func dismantleUIViewController(_ controller: AVPlayerViewController, coordinator: ()) {
        controller.player = nil
    }
}
