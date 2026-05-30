# InputMethodsDemo

An iOS host app for trying the package's domain-specific input widgets in the
Simulator — something SwiftUI previews can't fully exercise (touch feedback,
hardware-keyboard input, focus, live bindings).

Currently demonstrates:

- `HexKeyboardInput` — hex payload entry with grouped-byte display, return-key
  variants, and a live state / sent-payload log.
- `VINKeyboardInput` — VIN keypad with QWERTZ/QWERTY layouts, WMI/VDS/VIS
  grouping, check-digit highlight, and live validation state.

## Build & run

The Xcode project is generated from `project.yml` with
[XcodeGen](https://github.com/yonaskolb/XcodeGen) and is intentionally not
checked in. Generate it, then open or build:

```bash
cd Demo
xcodegen generate
open InputMethodsDemo.xcodeproj
```

Or from the command line:

```bash
cd Demo
xcodebuild -project InputMethodsDemo.xcodeproj -scheme InputMethodsDemo \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' build
```

The app depends on the parent `CornucopiaSUI` package via a local path
reference, so changes to the library are picked up directly.
