# CornucopiaSUI Demo

An iOS host app for trying the package under realistic Simulator conditions:
touch feedback, hardware-keyboard input, focus, live bindings, sheets, overlays
and system wrappers that SwiftUI previews cannot fully exercise.

The first screen is a navigable catalog with stable accessibility identifiers
(`demo.row.<item>` and focused `demo.<area>` IDs) so the app can double as a
future UI-test fixture.

Currently demonstrates:

- Domain input widgets: `HexKeyboardInput`, `VINKeyboardInput`,
  `IPv4KeyboardInput` and `MACKeyboardInput`.
- Validated text entry: `StyledTextField`, `NetworkAwareTextField` and
  `VINTextField`.
- Async controls and overlays: `BusyButton`, `GenericBusyButton`,
  `ConfirmationBusyButton`, `CC_confirmationDialog` and
  `CC_notificationCapsule`, including inline busy progress with indeterminate
  and determinate states, Drops-inspired queueing, actions, top/bottom
  placement, custom colors and standard/glass backgrounds. The confirmation
  dialog screen also shows standard and glass surface variants.
- Slide-over setup cards: `CC_slideOverCard` with welcome, item-driven setup,
  pairing, glass, full-width, required-step and focused text-field variants.
- Text and motion components: `MarqueeText`, `MarqueeScrollView`,
  `BlendingTextLabel`, `SynchronizedBlendingTextLabel` and
  `SynchronizedBlendingContainer`.
- View modifiers: `CC_blinking`, `CC_debouncedTask`, `CC_onFirstAppear`,
  `CC_measureSize`, `CC_task` and `CC_presentationDetentAutoHeight`.
- Navigation and system helpers: `NavigationController`,
  `ObservableReachability`, `ObservableLocalNetworkAuthorization`,
  `ObservableBusyness`, `DevicePickerView`, `ImagePickerView`,
  `UIImage.CC_resized(height:)` and
  `UIApplication.CC_withIdleTimerDisabled`.

The demo app includes local-network and photo-library usage descriptions because
the system utility screen can trigger those framework paths.

## Build & run

The Xcode project is generated from `project.yml` with
[XcodeGen](https://github.com/yonaskolb/XcodeGen) and is intentionally not
checked in. Generate it, then open or build:

```bash
cd Demo
xcodegen generate
open CornucopiaSUIDemo.xcodeproj
```

Or from the command line:

```bash
cd Demo
xcodebuild -project CornucopiaSUIDemo.xcodeproj -scheme CornucopiaSUIDemo \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' build
```

The app depends on the parent `CornucopiaSUI` package via a local path
reference, so changes to the library are picked up directly.

For focused slide-over card launches, open the `slideOverCard` demo item and set
`CORNUCOPIA_DEMO_SLIDEOVER_CARD` to `welcome`, `flow`, `pair`, `glass`,
`fullWidth`, `required` or `textField`. The `textField` variant auto-focuses an
input to exercise keyboard avoidance and animated content-height changes on
iPhone and iPad.
