# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

### Build
```bash
swift build
```

### Run Tests
```bash
swift test
```

### Run a Single Test
```bash
swift test --filter <TestClassName>/<testMethodName>
```

### Build for specific platform
```bash
swift build -Xswiftc "-sdk" -Xswiftc "`xcrun --sdk iphonesimulator --show-sdk-path`" -Xswiftc "-target" -Xswiftc "x86_64-apple-ios16.0-simulator"
```

## Architecture

CornucopiaSUI is a SwiftUI utility library that extends the Cornucopia ecosystem. It provides reusable components and utilities for SwiftUI applications across Apple platforms.

### Core Dependencies
- **CornucopiaCore**: Parent library providing foundational types like `Logger`, `Protected` property wrapper, and `BusynessObserver` protocol

### Key Architectural Patterns

#### Observable State Management
The library uses `ObservableObject` pattern for state management:
- `NavigationController`: Manages navigation stack with type-safe path tracking
- `ObservableBusyness`: Debounced busy state provider implementing `BusynessObserver`
- `ObservableLocalNetworkAuthorization`: Singleton for network authorization state
- `ObservableReachability`: Network reachability monitoring
- `NotificationCapsuleController`: Transient notification capsule with styles (info/success/warning/error/activity)

#### View Modifier Pattern
Custom view modifiers follow the pattern of creating a struct conforming to `ViewModifier` with a corresponding extension method prefixed with `CC_`:
- Example: `PersistentTaskModifier` with `.CC_task()` extension method
- Example: `NotificationCapsuleModifier` with `.CC_notificationCapsule()` extension method

#### Navigation System
`NavigationController` provides centralized navigation management:
- Type-safe navigation with `NavigationPath`
- Tracks element types for `pathContains()` functionality using type identity
- Shared via `EnvironmentValues.CC_navigationController`

### Naming Conventions
- Public API extensions are prefixed with `CC_` (e.g., `CC_task`, `CC_navigationController`)
- Internal logging uses `Cornucopia.Core.Logger()`
- View modifiers are suffixed with `Modifier` in the struct name

### Platform Support
- iOS 17+, macOS 13+, tvOS 17+, watchOS 10+
- Platform-specific code uses availability checks (e.g., `#available(iOS 16.0, *)`)

## Design Notes: Domain-Specific Input Widgets

Specialized input widgets are useful when an input is not free text, but a small domain-specific protocol. Their value is not just a custom keyboard: the widget can move domain rules directly into the input flow, including allowed characters, grouping, validity, submit conditions, visual semantics, and error prevention.

`HexKeyboardInput` is the current reference example. Compared with a generic `TextField`, it prevents invalid characters, keeps byte payloads readable, handles odd-nibble constraints, normalizes copy/paste input, exposes clear/delete/send as domain actions, and makes the common path fast.

Good candidates for similar reusable controls in Cornucopia apps:

- Diagnostic and terminal flows:
  - CAN IDs such as `7DF`, `7E0`, `7E8`, with 11-bit/29-bit mode switching.
  - UDS service payload entry, with the service byte and parameters visually grouped.
  - ISO-TP payload composition, including length, padding, frames, and TesterPresent commands.
  - Masks and filters such as `0x7FF`, `0x700-0x7FF`, and RX/TX pairs.
  - Baudrate/channel pickers with valid presets instead of free numeric input.
- VIN and vehicle data:
  - VIN entry with uppercase normalization, 17-character state, and I/O/Q exclusion.
  - WMI/VDS/VIS grouping and inline check-digit status.
  - Manufacturer/country hints derived from the typed VIN.
- Network and adapter configuration:
  - IP/host/port inputs with separated octets and range validation.
  - MAC address or Bluetooth identifier entry using hex pairs.
  - BLE UUID entry using `8-4-4-4-12` segment grouping.
  - Endpoint builders that separate scheme, host, port, and path.
- Technical values and measurement inputs:
  - Voltage, current, torque, temperature, and similar values with fixed unit semantics.
  - Min/max/step validation at input time.
  - Presets with manual override.
  - Decimal/hex/binary switching for register values.
- Command and macro workflows:
  - Command-chip inputs for frequent diagnostic commands.
  - History-aware payload entry.
  - Template buttons for payloads such as `22 F1 90`, `10 03`, or `3E 00`.
  - Send-and-repeat controls with interval validation.

Build one of these controls when at least two of these are true:

- The input has hard syntax rules.
- Mistakes are expensive, common, or disruptive.
- Users enter this type of value repeatedly.
- The displayed form differs from the stored value.
- There is a natural keypad, grouping, or action layout.
- Validity directly controls actions such as Send, Connect, or Save.

Keep these widgets reusable by treating them as small domain controls: bind a normalized value, expose clear validation and submit rules, keep app-specific business logic out of the component, and provide helper parsers/formatters when they are part of the public contract.

### Shared keypad conventions (Hex / VIN / IPv4 / MAC)

The four keypad widgets (`HexKeyboardInput`, `VINKeyboardInput`, `IPv4KeyboardInput`, `MACKeyboardInput`) share their chrome through a small toolkit in `Sources/CornucopiaSUI/Views/Keypad/`: `KeypadKeyStyle`/`KeypadKeyColors`/`KeypadKeyRole` (rendering — each widget keeps its own role enum and conforms it to `KeypadKeyRole` for the palette), `KeypadInlineButtonStyle` (the `✕` clear button), `KeypadKey` (the value-key button, incl. long-press alternates), `KeypadSlotCursor`, and `CC_keypadHardwareInput` + `keypadPasteboardString` (hardware keyboard / paste). A new keypad should reuse these rather than re-implement them. The shared conventions:

- **Slot display + cursor.** The value is shown as grouped, color-coded slots with a section label (e.g. `OCT 1`, `B1`, WMI/VDS/VIS). The active slot shows a single text-style cursor (`|`) that pulses slowly (`.easeInOut(duration: 0.8).repeatForever(autoreverses: true)`, driven by an `isActiveSlotPulsing` flag set in `.task`). Inactive slots keep the glyph at zero opacity so it still anchors the baseline the separators align to — do not render multiple visible cursors. Separators (`.`/`:`/`-`) are baseline-aligned to the value digits, not center-aligned to the two-line cell.
- **Auto-advance & input gating.** Advance to the next slot automatically once a slot is full (IPv4: after the third digit). Gate impossible input at the key level by disabling the key (`.disabled(...)`) rather than accepting then rejecting — e.g. IPv4 greys out digits that would push an octet past 255, MAC caps at 12 nibbles, VIN disables non-`X` letters at the check-digit position.
- **Zero-key emphasis.** The `0` key gets a filled accent-color background with a white glyph (the `.zero` role), matching `HexKeyboardInput`, because it is the most-used key on numeric keypads.
- **Long-press alternates.** `KeypadKey` takes an optional `alternates: [String]`; a long press opens a tap-to-pick popover of related values (a small corner dot marks keys that have them), while a plain tap still inserts the key's own value. IPv4 uses this for the subnet-mask octets (`IPv4KeyboardInput.maskAlternates`: hold `1`→`128`/`192`, hold `2`→`224`…`255`), selecting one replaces the active octet and advances. The same mechanism supports a `.com`-style dedicated key (primary value on tap, siblings on hold) for a future host/URL keypad. Only populate alternates where they're genuinely useful — VIN deliberately has none.
- **Paste (`⌘V` / `Ctrl+V`).** These are custom focusable views using `onKeyPress`, not `UITextField`, so paste must be intercepted manually — handled centrally by `CC_keypadHardwareInput`. It checks `press.modifiers` for `.command`/`.control` **first**: `v` triggers the widget's `paste()` (reads `keypadPasteboardString`, runs it through the widget's own normalizer, and **overwrites** the value); every other shortcut combo is swallowed (returned `.ignored`). This guard is mandatory for the hex keypad in particular, because hex letters (`A`–`F`) overlap with shortcut letters — without it, `⌘C`/`⌘A`/… would insert characters instead of acting as shortcuts.
- **Normalized binding.** The bound `text` is always kept in normalized form via `normalizeBoundText()` on `.onChange`, and each widget exposes a `static` normalizer/formatter (`normalizedIPv4Draft`, `normalizedMACHex`/`formattedMAC`, `normalizedHex`, `normalizedVIN`) as part of its public contract.

### VIN online decoding (NHTSA vPIC)

`VINKeyboardInput` optionally enriches the entry with make/model/year/type via the free NHTSA vPIC service (`VINVehicleDecoder.nhtsa`, opt-in through the `vehicleDecoder:` parameter). Behaviour:

- The decoder is **always queried** — NHTSA frequently resolves make/year (and sometimes model) even for non-US VINs, so there is no US-only gating.
- Decoding starts at **10 characters** (VIN positions 1–10 carry make/descriptor/model-year; only the serial number follows). `.task(id:)` debounces edits and cancels stale lookups.
- **Model year is shown offline immediately** from position 10 via `VINTextField.modelYear(forPosition10:)`, then overwritten by the online value when present. Make falls back to the offline WMI manufacturer; model and vehicle type are online-only.
- The vehicle widget shares the analysis column with the offline country/manufacturer preview: identity while typing, vehicle once ≥10 characters are present.

#### Offline WMI data stance

CornucopiaSUI intentionally keeps offline VIN decoding small and conservative by using `Automotive-Swift/VIN` as the source of truth for syntax, check digit, WMI/region/manufacturer, and model-year preview. Do **not** replace this with a larger scraped WMI table such as `Wal33D/nhtsa-vin-decoder`: that project has broader WMI coverage, but local comparison found several questionable manufacturer mappings, so it is not clearly better for trusted UI hints.

If offline support is expanded later, prefer targeted additions to `Automotive-Swift/VIN` with tests over importing a second VIN/WMI database into CornucopiaSUI. Keep richer vehicle details (`model`, `trim`, `engine`, `bodyClass`, plant data, etc.) behind the optional online `VINVehicleDecoder` path; a complete offline vPIC-style data set would be much larger and does not belong in this SwiftUI utility library by default.

#### Verified test VINs (NHTSA returns data)

Serial sections are partly synthetic (so the check digit may mismatch, `ErrCode 1`), but WMI/VDS/position-10 are real, so NHTSA decodes them reliably.

| VIN | Decodes to | Notes |
|---|---|---|
| `1HGCM82633A004352` | 2003 Honda Accord · Passenger Car · Coupe | only one with `ErrCode 0` |
| `5YJ3E1EA7JF005252` | 2018 Tesla Model 3 · Passenger Car · Sedan | |
| `1FTFW1ET5DFC10312` | 2013 Ford F-150 · Truck · Pickup | non-"Passenger Car" type |
| `5UXWX9C50H0T15998` | 2017 BMW X3 · MPV · SUV | non-"Passenger Car" type |
| `WP0AB29948S730159` | 2008 Porsche 911 · Passenger Car · Coupe | |
| `1G1YY26U965105430` | 2006 Chevrolet Corvette · Passenger Car · Coupe | |
| `WBA3A5C50CF256736` | 2012 BMW 328i · Passenger Car · Sedan | German WMI, full hit (proves non-US decoding) |
| `WVWZZZ1KZ9W000001` | 2009 Volkswagen | make + year only, no model (offline fills the rest) |
| `WAUZZZ8K9BA021189` | Audi · Passenger Car | make/type only |

Test the 10-character partial path by typing only through position 10 (e.g. `1FTFW1ET5D`) — decoding should fire before the remaining characters are entered.
