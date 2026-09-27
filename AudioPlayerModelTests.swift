import XCTest
@testable import InteraMusic

@MainActor
final class AudioPlayerModelTests: XCTestCase {
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
