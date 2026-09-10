# Changelog

[← Back to ChordMouse](README.md)

## 0.2.2 — Reliable normal clicks

- Replays a short normal click as one matching down/up pair instead of combining a replayed down event with the original up event.
- Replays the first drag event with its matching mouse-down when a normal click becomes a drag.

## 0.2.1 — Configurable controls and click reliability

- Added per-gesture action selection for drag, held-button click, repeated click, and middle-button scroll inputs.
- Added back/forward, tabs, media, volume, brightness, zoom, Focus Zoom, undo/redo, Mission Control, App Exposé, and desktop actions.
- Added launch at login and Korean interface support when macOS uses Korean.
- Removed the simultaneous two-button double-click action.
- Fixed a pending click being dropped when macOS reconnects the global input tap.

## 0.1.0 — Initial release preparation

This entry describes the local v0.1.0 build. The GitHub Release and downloadable app are not published yet.

### Features

- Four-direction gestures using the left and right mouse buttons together
- Desktop navigation, Mission Control, and App Exposé
- Menu-bar controls for starting, pausing, and checking permission
- Reads the Mission Control shortcuts configured in macOS
- Swaps left/right desktop direction
- Launch at login

### Planned release artifact

- File: `ChordMouse-0.1.0-macOS-arm64.zip`
- Supported platform: macOS 13+ on Apple Silicon
- Signing: local ad-hoc signing
- Developer ID signing and Apple notarization: not completed

### Known limitations

- An ordinary click may wait up to about 230 ms
- No continuous swipe animation or inertia
- Possible conflicts with other mouse utilities
- No Intel release build
