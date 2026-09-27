import XCTest
import Combine
@testable import InteraMusic

@MainActor
final class AudioPlayerModelTests: XCTestCase {
    func testBuiltAppKeepsFullScreenLaunchConfiguration() {
        XCTAssertNotNil(Bundle.main.object(forInfoDictionaryKey: "UILaunchScreen"))
        XCTAssertEqual(Bundle.main.object(forInfoDictionaryKey: "LSSupportsOpeningDocumentsInPlace") as? Bool, true)
    }

    func testFolderIncludesNestedMusicAndSkipsHiddenFilesAndLinks() throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let nested = folder.appendingPathComponent("Artist/Album")
        try FileManager.default.createDirectory(at: nested, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        for relative in ["root.mp3", "Artist/Album/song.M4A", "Artist/Album/notes.txt",
                         "Artist/Album/.hidden.mp3"] {
            try Data().write(to: folder.appendingPathComponent(relative))
        }
        try FileManager.default.createSymbolicLink(
            at: folder.appendingPathComponent("link.mp3"),
            withDestinationURL: folder.appendingPathComponent("root.mp3")
        )
        let player = AudioPlayerModel()
        player.chooseFolder(folder)
        XCTAssertEqual(Set(player.tracks.map { $0.url.lastPathComponent }), ["root.mp3", "song.M4A"])
    }

    func testReadsEmbeddedArtworkFromAudioFile() async throws {
        let url = try XCTUnwrap(Bundle(for: Self.self).url(forResource: "with-artwork", withExtension: "mp3"))
        let image = await AudioPlayerModel.embeddedArtwork(at: url)
        XCTAssertNotNil(image)
    }

    func testFileWithoutArtworkUsesFallback() async throws {
        let url = try XCTUnwrap(Bundle(for: Self.self).url(forResource: "without-artwork", withExtension: "mp3"))
        let image = await AudioPlayerModel.embeddedArtwork(at: url)
        XCTAssertNil(image)
    }

    func testChangingSongClearsPreviousArtwork() async throws {
        let covered = try XCTUnwrap(Bundle(for: Self.self).url(forResource: "with-artwork", withExtension: "mp3"))
        let plain = try XCTUnwrap(Bundle(for: Self.self).url(forResource: "without-artwork", withExtension: "mp3"))
        let player = AudioPlayerModel()
        let loaded = expectation(description: "Song artwork loads")
        let subscription = player.$currentArtwork.compactMap { $0 }.first().sink { _ in loaded.fulfill() }
        defer { subscription.cancel(); player.pause() }
        player.openIncomingFile(covered)
        await fulfillment(of: [loaded], timeout: 10)
        XCTAssertNotNil(player.currentArtwork)
        player.openIncomingFile(plain)
        XCTAssertNil(player.currentArtwork)
    }

    func testAppContainsHomeScreenIcon() {
        let icons = Bundle.main.object(forInfoDictionaryKey: "CFBundleIcons") as? [String: Any]
        let primary = icons?["CFBundlePrimaryIcon"] as? [String: Any]
        XCTAssertEqual(primary?["CFBundleIconName"] as? String, "AppIcon")
    }

    func testUnreadableFolderReportsFailure() {
        let player = AudioPlayerModel()
        player.chooseFolder(URL(fileURLWithPath: "/missing-\(UUID().uuidString)"))
        XCTAssertNotNil(player.errorMessage)
        XCTAssertTrue(player.tracks.isEmpty)
    }

    func testEmptyFolderClearsPreviousPlaybackState() throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let player = AudioPlayerModel()
        player.progress = 12
        player.duration = 50
        player.isPlaying = true
        player.chooseFolder(folder)
        XCTAssertEqual(player.folderName, folder.lastPathComponent)
        XCTAssertEqual(player.progress, 0)
        XCTAssertEqual(player.duration, 0)
        XCTAssertFalse(player.isPlaying)
        XCTAssertNotNil(player.errorMessage)
    }

    func testInvalidAudioDoesNotClaimToBePlaying() throws {
        let file = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(UUID().uuidString).mp3")
        try Data("invalid audio".utf8).write(to: file)
        defer { try? FileManager.default.removeItem(at: file) }
        let player = AudioPlayerModel()
        player.openIncomingFile(file)
        XCTAssertFalse(player.isPlaying)
        XCTAssertNotNil(player.errorMessage)
    }
}
