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
