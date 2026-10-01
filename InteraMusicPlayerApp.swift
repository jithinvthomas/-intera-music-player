import SwiftUI

@main
struct InteraMusicPlayerApp: App {
    @StateObject private var player = AudioPlayerModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(player)
                .task { player.restoreLastFolder() }
                .onOpenURL { url in
                    player.openIncomingFile(url)
                }
        }
    }
}