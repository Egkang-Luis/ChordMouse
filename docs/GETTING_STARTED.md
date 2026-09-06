# Getting started

[← Back to ChordMouse](../README.md)

## Requirements

- macOS 13 or later
- Apple Silicon Mac (M-series) for the current release build
- A mouse with left and right buttons
- Accessibility permission

## Install ChordMouse

The v0.1.0 download is not published to GitHub Releases yet. Once it is available, download the ZIP, unzip it, and move ChordMouse.app to your Applications folder.

The current build is locally signed and has not yet received Developer ID signing or Apple notarization. macOS may restrict opening an app downloaded from GitHub.

## Allow Accessibility access

1. Open **System Settings → Privacy & Security → Accessibility**.
2. Allow **ChordMouse**. If it is not listed, click **+** and select ChordMouse.app from Applications.
3. In the menu bar, select **⇄ → Recheck permission / Start**.
4. If the change does not take effect, quit and reopen the app.

ChordMouse needs this permission to detect mouse input globally and send the configured macOS shortcuts.

## Use a gesture

Press both mouse buttons within about 230 ms, then drag while holding them. Release both buttons before starting the next gesture.

| Direction | Default action |
| --- | --- |
| Left | Next desktop |
| Right | Previous desktop |
| Up | Mission Control |
| Down | Show windows for the current app |

**Swap left/right desktop direction** is enabled by default. Turn it off in the menu to reverse the left and right actions.

## Menu options

- **Pause**: temporarily disables gestures.
- **Swap left/right desktop direction**: reverses desktop navigation direction.
- **Launch at login**: starts ChordMouse when you sign in. If approval is required, allow it in **System Settings → General → Login Items & Extensions**.
- **Reload current system shortcuts**: use this after changing Mission Control shortcuts in macOS.

## Troubleshooting

### The mouse input is not detected

Check whether the menu input status changes when you hold both buttons. If it does not, verify Accessibility permission and disable mouse-button remapping or other gesture utilities temporarily.

### The gesture triggers, but the desktop does not move

Open **System Settings → Keyboard → Keyboard Shortcuts → Mission Control** and make sure the relevant shortcut is enabled. Test it directly from the keyboard, then select **Reload current system shortcuts** in ChordMouse. Desktop navigation also requires at least two desktops.

### Permission stopped working after replacing the app

After rebuilding, re-signing, or moving the app, remove its previous entry from Accessibility and add the current app again.

### A normal click feels delayed

ChordMouse waits up to about 230 ms for the second mouse button. This is an expected behavior of the current version.
