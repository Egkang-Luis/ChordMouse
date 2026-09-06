<div align="center">

# ChordMouse

### Navigate your Mac with one mouse gesture.

Hold the left and right mouse buttons together, then drag in a direction.  
ChordMouse triggers the macOS shortcuts you already use for desktop navigation and window management.

**macOS 13+ · Apple Silicon · Menu bar app**

[Getting started](docs/GETTING_STARTED.md) · [Changelog](CHANGELOG.md) · [Releases](https://github.com/Egkang-Luis/ChordMouse/releases)

</div>

---

## Trackpad gesture or ChordMouse — same destination

*An illustrated interaction demo is being prepared for this page. It explains the interaction and is not a screen recording.*

## Four directions, four actions

| Drag direction | Default action |
| :---: | --- |
| ← Left | Next desktop |
| → Right | Previous desktop |
| ↑ Up | Mission Control |
| ↓ Down | App Exposé — show windows for the current app |

ChordMouse starts with **Swap left/right desktop direction** enabled. Turn it off in the menu if you prefer the opposite desktop direction.

## Designed to stay out of the way

- Lives in the menu bar and does not appear in the Dock.
- Uses your current macOS Mission Control keyboard shortcuts.
- Can launch automatically when you sign in.
- Lets you pause gestures or swap desktop direction from the menu.

## Installation

**Version 0.1.0 is being prepared.** The downloadable release has not been published yet.

When it is available:

1. Download the ZIP file from [Releases](https://github.com/Egkang-Luis/ChordMouse/releases) and unzip it.
2. Move **ChordMouse.app** to **Applications**, then open it.
3. In **System Settings → Privacy & Security → Accessibility**, allow ChordMouse.
4. Click **⇄ → Recheck permission / Start** in the menu bar.
5. Press the left and right buttons nearly together, then drag while holding both.

Release builds currently target **Apple Silicon Macs running macOS 13 or later**. The first build uses local ad-hoc signing; Developer ID signing and Apple notarization are not complete yet, so macOS may restrict opening the downloaded app.

[Full installation and troubleshooting guide →](docs/GETTING_STARTED.md)

## Current limitations

- An ordinary click may be delayed by up to about 230 ms while ChordMouse waits to detect a two-button chord.
- Each gesture sends one shortcut; it does not provide a continuous, inertial desktop swipe.
- Other mouse remapping or gesture utilities can interfere.
- An Intel build is not available yet.

## Feedback

Open an [issue](https://github.com/Egkang-Luis/ChordMouse/issues) with your macOS version, Mac model, mouse model, and the steps that reproduce the problem.
