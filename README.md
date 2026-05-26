# FocusWriter

A distraction-free writing app for macOS. No toolbars, no formatting options, no clutter — just you and your words on a calm dark screen.

Built as a bespoke single-purpose tool for focused writing.

## Features

- Dark background with soft grey text (Georgia, 18pt)
- Hidden title bar for full immersion
- Open, save, and create text files (Cmd+O, Cmd+S, Cmd+N)
- Save As with Cmd+Shift+S
- Drag and drop text files to open them
- Unsaved changes indicator
- Goes full screen beautifully

## Build & Install

Requires macOS 13+ and Swift 5.9+.

```
swift build -c release
cp -R .build/release/FocusWriter /Applications/FocusWriter.app/Contents/MacOS/
```

Or build the full .app bundle:

```
swift build -c release
mkdir -p /Applications/FocusWriter.app/Contents/MacOS
cp .build/release/FocusWriter /Applications/FocusWriter.app/Contents/MacOS/
cp Info.plist /Applications/FocusWriter.app/Contents/
```

## License

Free to use. Do whatever you want with it.
