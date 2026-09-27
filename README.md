# Intera Music Player

## iPhone fixes
- Top-left menu offers Choose folder and Open audio file.
- The background fills the display; the menu respects the safe area and content scrolls on short screens.
- Intera logo is bundled as the player artwork.
- Folder/file security access is retained until the selection changes.
- Import and playback failures display an explanation.
- Folders load supported audio files directly inside that folder.

## Verify before packaging
On a Mac with Xcode and XcodeGen:
1. Run `xcodegen generate`.
2. Open `InteraMusicPlayer.xcodeproj` and choose an iPhone simulator.
3. Run Product > Test. Test on a small iPhone and a notched iPhone.
4. On a signed development build on an iPhone, open the top-left menu > Choose folder.
5. Select a folder in Files with at least two downloaded songs. Play both, skip tracks, pause/resume, and change folders.
6. Check cancelling the picker, an empty folder, a file with invalid audio, and an iCloud file that is not downloaded.
7. Check portrait, landscape, and larger accessibility text. The menu must remain visible and the playlist reachable by scrolling.

The simulator workflow builds and tests without generating an IPA.
Real iPhone folder-provider permissions require a device test.
