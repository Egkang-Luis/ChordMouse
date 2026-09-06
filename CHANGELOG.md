# Changelog

[← Back to ChordMouse](README.md)

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
