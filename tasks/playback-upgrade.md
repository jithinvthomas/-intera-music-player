# Broad media playback and video controls

User-authorized implementation, 2 October 2026.

## Scope
The first video release failed to open the user's MP4. The exact failure stage is still unknown; an asynchronous question asks whether Files disabled the item, an error appeared, or playback was blank. Address both restrictive picker types and native decoder limitations without claiming universal support.

## Build order
1. Integrate checksum-verified MobileVLCKit 3.7.3 from its official CocoaPods distribution; preserve passing native music behavior.
2. Add a shared VLC playback adapter; use it for video and as music fallback when AVAudioPlayer cannot decode a file.
3. Build accessible video controls: play/pause, seek, skip 10 seconds, speed, full-screen chrome toggle, rotate via UIWindowScene geometry, Fit/Fill/Stretch, audio tracks, embedded subtitles/off, external subtitle import.
4. Allow Files selection independent of provider UTType; expand the music scan extension set and incoming-file routing. Retain scoped access for playback and subtitles.
5. Test generated MP4/MKV/AVI samples, multiple audio/subtitle tracks, Ogg/Opus/FLAC audio, unsupported files, handoff, interruptions and close cleanup. Build and deliver an IPA after both CI jobs pass.

## Acceptance
- Common local codecs beyond AVFoundation decode with real fixture tests; unknown/corrupt/protected media gets a clear error.
- Music and video never play simultaneously; selecting new media cancels stale pending playback/resume.
- Audio and subtitle menus use real stream IDs, not array positions; selecting Off disables subtitles.
- Import SRT/ASS/SSA/VTT files from Files, keep access while needed, surface failures.
- Fit preserves the whole frame, Fill crops to screen, Stretch fills without preserving aspect; rotation controls use supported public iOS APIs.
- Controls have accessible labels, usable touch targets, visible close/back actions, and fit portrait/landscape.
- Include VideoLAN attribution, license text and source/rebuild instructions.

## Limits
No guarantee for every format, malformed file, encrypted media or unsupported codec. Hardware decoding, battery cost and high-resolution playback vary by device. PiP, downloaded-video library, and Continue Watching remain separate features.

## Verification
Both CI runners build the workspace and run XCTest. Real device verification remains required for the user's MP4, file providers, rotation, calls and Bluetooth. Do not claim the user's specific file is fixed without a device result.

Sources: https://github.com/videolan/vlckit (3.0 API branch), https://github.com/CocoaPods/Specs/blob/master/Specs/b/f/7/MobileVLCKit/3.7.3/MobileVLCKit.podspec.json
