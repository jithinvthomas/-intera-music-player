# Media app roadmap

## Current update
- Remember and reopen the last selected music folder without autoplay.
- Pause for calls and resume the same track when iOS permits it.
- Keep physical volume buttons dedicated to volume unless the user clarifies a different intent.
- Regression tests and real-device checks cover folder access and audio interruptions.

## Approved identity: Jiza
Jiza combines Jithin and Elizabeth. The user selected Jiza as the app and repository name.
Logo: a fused J/Z monogram with a forward-facing opening.
Theme: midnight charcoal #111B21, jade #45D6AC, ivory #F6F5F0 and slate #A8B7BD.
The dark theme is applied to the current player; an ivory light mode is a later option.
Brand/IDENTITY.md records the assets, prompts and colour usage.
Use a descriptive App Store subtitle as future features ship.

## Stage 2: Video
Add a video library and native playback with AVKit. Start with formats/codecs supported by iOS;
show clear unsupported-format messages. Add resume position, full-screen playback, subtitles
and Picture in Picture where supported. Keep one active playback session across audio/video.
Decide whether broader codec support justifies an additional playback library after native playback works.

## Stage 3: Files and downloads
Add Library, Files and Downloads navigation as each feature becomes usable.
Support folders, search, rename, move, share, storage information and explicit delete confirmation.
Start downloads from direct HTTP/HTTPS links, with queue, progress, cancel, retry and resume
when supported by the server. Use background URLSession and persist task identifiers.
Restore the download list after relaunch and handle low storage, filename collisions and failed transfers.
Downloaded files may be stored even when the app cannot preview their format.
Do not promise that every streaming service or protected media source can be downloaded.

## Stage 4: Integrated browser
Add WebKit browsing, tabs, bookmarks, history controls and supported website downloads.
Connect web downloads to Files and the download queue using WKDownload where appropriate.
Keep private browsing data separate from normal browsing and make deletion controls clear.
Start as an integrated browser; reconsider a standalone browser after this is reliable.
Worldwide availability is an ambition, not a guarantee that every site can be reached:
network restrictions, site policies, regional availability and authentication remain relevant.

## Sources
- Audio interruptions: https://developer.apple.com/documentation/avfaudio/handling-audio-interruptions
- Directory access: https://developer.apple.com/documentation/uikit/providing-access-to-directories
- Background downloads: https://developer.apple.com/documentation/foundation/downloading-files-in-the-background
- Browser downloads: https://developer.apple.com/documentation/webkit/wkdownload
- Reference product: https://support.readdle.com/documents/built-in-browser-download-manager
