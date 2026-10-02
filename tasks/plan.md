# Jiza next phase: Music + Video

Status: first video increment authorized and implemented, 2 October 2026. Device validation remains pending.

## Outcome
Open a video from Files or a remembered folder, play it full screen, and return to its saved position later. Keep music reliable while introducing a shared Library with Music and Videos filters, a music mini-player, and the existing Cobalt Glass identity.

## Starting point
- Audio-session fix 4e23d93 passed both simulator jobs; replacement IPA delivered. User confirmed music playback works. Real call and provider checks remain pending.
- Existing app uses SwiftUI, AVAudioPlayer, folder bookmarks, and a single player/library screen.
- Explicit supported orientations and a new rotation test have been added. Check the latest CI evidence before marking the old landscape gap resolved.

## Decisions
- Prove single-file video playback early, before redesigning the library.
- Use AVPlayer with AVPlayerViewController presented through SwiftUI for native controls, full screen, and supported Picture in Picture. Keep the existing audio engine initially.
- Starting one media player pauses the other. A call must not resume an old music session after the user switches to video.
- Start with local MP4/MOV samples using device-supported codecs; assess actual playability rather than promising support from an extension alone.
- Remember video position using a stable file reference, never the current Track UUID that changes on every scan. Restore folders without autoplay.
- Retain original provider URLs with scoped access. Avoid silently copying whole video libraries into app storage.
- Keep cobalt accents and native glass on controls; use readable, simple surfaces for media content and retain older-iOS and accessibility fallbacks.
- Support embedded subtitle/audio choices where available. External subtitle import and broader codec libraries are later work.

## Delivery order
1. Confirm current music behavior and repair/test landscape.
2. Open one local video with native playback and safe audio handoff.
3. Add video folders, thumbnails, search, and Music/Videos library filters.
4. Add saved position and Continue Watching.
5. Verify Picture in Picture, interruptions, accessibility, and package an iPhone test IPA.

Task details and acceptance checks: [todo.md](todo.md).

## Release checks
Both existing CI simulator jobs pass; restore orientation coverage rather than removing failures. Real iPhone checks cover playback, file-provider access after relaunch, calls, Bluetooth, hardware volume, full screen and Picture in Picture. Test large text, Reduce Transparency, dark/light mode and landscape. Use representative valid, unsupported, unavailable and corrupt media samples.

## Later releases
- Files and direct-link downloads: folders, share/move/rename, persistent queue, progress, cancel/retry, server-supported resume and storage handling.
- Integrated browser: browsing, tabs, bookmarks and supported website downloads connected to Files.
- Reassess a standalone browser after the integrated experience works. Do not promise universal site access or downloads from every service.

## Risks
- Native codec support varies by file/device: test samples and show useful unsupported-media errors.
- Cloud/provider files may be unavailable: provide retry/reselect actions and test downloaded and unavailable files.
- Two engines can overlap or resume incorrectly: explicit ownership and interruption tests before library expansion.
- Thumbnail work can slow large folders: load asynchronously, cancel off-screen work and bound caching.

## Open decisions
- Proposed priority is local video before downloads; user may choose a different sequence.
- Confirm video playback and interruption behavior on the user's iPhone after installing the video IPA.

## Source
Apple AVPlayerViewController: https://developer.apple.com/documentation/avkit/avplayerviewcontroller

This supports the choice of native player controls and Picture in Picture; final device behavior must be verified during implementation.
