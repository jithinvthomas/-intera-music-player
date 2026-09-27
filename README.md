# Intera Music Player

## iPhone fixes
- Top-left menu offers Choose folder and Open audio file.
- The background fills the display; the menu respects the safe area and content scrolls on short screens.
- The home-screen icon uses the Intera symbol without wording.
- The player displays embedded song artwork, with the Intera symbol as the fallback.
- Folder/file security access is retained until the selection changes.
- Import and playback failures display an explanation.
- Folder selection includes supported audio in subfolders, skips hidden files and symbolic links, and retains distinct files with matching names.

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

## Artwork and icon checks
- TestFixtures contains generated 0.3-second audio with and without embedded cover art.
- Tests verify embedded artwork, missing-artwork fallback, clearing the cover on song changes,
  recursive folder discovery, and the built app's home-screen icon registration.
- On your iPhone, choose a parent folder containing songs in nested folders.
- Switch between songs with and without embedded cover art. The previous cover must clear.
- After installing, confirm the home-screen icon shows only the Intera symbol.

The icon was adapted from the supplied Intera brand image using the built-in image tool.
Prompt: isolate the existing globe/orbit/document-checkmark symbol from the right-hand icon,
preserve its colors and identity, remove all wording and divider lines, center on an opaque
deep navy square with no exterior rounded corners. The output was resized into Apple's icon sizes.
