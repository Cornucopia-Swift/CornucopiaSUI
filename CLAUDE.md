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