# CornucopiaSUI

_🐚 The "horn of plenty" – a symbol of abundance._

A SwiftUI utility library that extends the Cornucopia ecosystem with reusable components, view modifiers, and tools for building polished SwiftUI applications across all Apple platforms.

## Platform Support

- iOS 16+
- macOS 13+
- tvOS 16+
- watchOS 9+

## Installation

### Swift Package Manager

Add CornucopiaSUI as a dependency to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/Cornucopia-Swift/CornucopiaSUI", branch: "master")
]
```

Or add it through Xcode:
1. **File** → **Add Package Dependencies...**
2. Enter the repository URL: `https://github.com/Cornucopia-Swift/CornucopiaSUI`
3. Select the **master** branch
4. Add to your target

## What's Included

### 🎛️ View Modifiers
- **`CC_task`** - Persistent background tasks that survive view hierarchy changes
- **`CC_onFirstAppear`** - Execute code only on first view appearance
- **`CC_measureSize`** - Measure view dimensions
- **`CC_blink`** - Blinking animation effects
- **`CC_conditionalView`** - Conditional view rendering
- **`CC_debouncedTask`** - Debounced task execution
- **`CC_invisibleNavigation`** - Hide navigation elements
- **`CC_debugPrint`** - Debug printing for development
- **`CC_presentationDetentAutoHeight`** - Auto-sizing sheet presentation

### 📱 Views & Components
- **`BusyButton`** - Buttons with built-in loading states
- **`MarqueeText`** - Smoothly scrolling text for long content
- **`BlendingTextLabel`** - Text with blending animations
- **`NetworkAwareTextField`** - Text fields that adapt to network state
- **`SingleAxisGeometryReader`** - Geometry reading for single axis
- **`ImagePickerView`** - UIKit image picker integration

### 🧭 Navigation
- **`NavigationController`** - Type-safe navigation stack management with programmatic control

### 🔧 Observable Tools
- **`ObservableBusyness`** - Debounced busy state management
- **`ObservableReachability`** - Network connectivity monitoring
- **`ObservableLocalNetworkAuthorization`** - Local network permission state

### 🎵 Audio & Media
- **`AudioPlayer`** - Simple audio playback utilities

### 📱 UIKit Integrations
- **`KeyboardAwareness`** - Keyboard state monitoring
- **`UIImage+Resize`** - Image resizing extensions
- **`UIApplication+AsyncIdleTimer`** - Async idle timer utilities

### 🎨 Extensions
- **Color+ForeignFrameworkColors** - Color compatibility helpers
- **Image+ForeignFrameworks** - Image framework integrations
- **ProcessInfo+Previews** - Preview environment helpers

## Usage Examples

### BusyButton - Loading States Made Easy

```swift
import SwiftUI
import CornucopiaSUI

struct ContentView: View {
    @State private var isLoading = false
    
    var body: some View {
        BusyButton(isBusy: $isLoading, title: "Upload Data") {
            // Your async operation here
            try await uploadData()
        }
        .buttonStyle(.borderedProminent)
    }
}
```

### NavigationController - Type-Safe Navigation

```swift
import SwiftUI
import CornucopiaSUI

struct AppView: View {
    @StateObject private var navigationController = NavigationController()
    
    var body: some View {
        NavigationStack(path: $navigationController.path) {
            ContentView()
                .environment(\.CC_navigationController, navigationController)
        }
    }
}

struct ContentView: View {
    @Environment(\.CC_navigationController) private var navigation
    
    var body: some View {
        Button("Go to Detail") {
            navigation?.push(DetailDestination.profile(userId: 123))
        }
    }
}

enum DetailDestination: Hashable {
    case profile(userId: Int)
    case settings
}
```

### MarqueeText - Scrolling Text

```swift
import SwiftUI
import CornucopiaSUI

struct TickerView: View {
    var body: some View {
        MarqueeText(
            "This is a very long text that will scroll horizontally when it doesn't fit",
            startDelay: 2.0
        )
        .font(.headline)
        .frame(width: 200)
    }
}
```

### Persistent Tasks - Background Work That Survives Navigation

```swift
import SwiftUI
import CornucopiaSUI

struct DataSyncView: View {
    @State private var syncProgress = 0.0
    
    var body: some View {
        VStack {
            ProgressView(value: syncProgress)
            Text("Syncing data…")
        }
        .CC_task {
            // This task continues even when view is removed from hierarchy
            await performLongRunningSyncOperation()
        }
    }
}
```

### ObservableBusyness - Debounced Loading States

```swift
import SwiftUI
import CornucopiaSUI

class DataManager: ObservableObject {
    private let busyness = ObservableBusyness(debounceInterval: .milliseconds(300))
    
    var isBusy: Bool { busyness.isBusy }
    
    func loadData() async {
        busyness.enterBusy()
        defer { busyness.leaveBusy() }
        
        // Perform data loading
        await performNetworkRequest()
    }
}
```

### First Appear Modifier - One-Time Setup

```swift
import SwiftUI
import CornucopiaSUI

struct AnalyticsView: View {
    var body: some View {
        ContentView()
            .CC_onFirstAppear {
                // Track screen view only once, not on every appear
                Analytics.trackScreenView("content_screen")
            }
    }
}
```

### Observable Network State

```swift
import SwiftUI
import CornucopiaSUI

struct NetworkStatusView: View {
    @StateObject private var reachability = ObservableReachability()
    
    var body: some View {
        VStack {
            Text("Network Status: \(reachability.isConnected ? "Connected" : "Offline")")
                .foregroundColor(reachability.isConnected ? .green : .red)
        }
        .onAppear {
            reachability.startMonitoring()
        }
    }
}
```

## Architecture

CornucopiaSUI builds upon **CornucopiaCore** and follows these key patterns:

- **Observable State Management** - Uses `ObservableObject` for reactive state
- **View Modifier Pattern** - Custom modifiers with `CC_` prefix for easy discovery
- **Type-Safe Navigation** - Centralized navigation with compile-time safety
- **Platform Consistency** - Unified APIs across all Apple platforms

## Testing

```bash
# Run all tests
swift test

# Run specific test
swift test --filter CornucopiaSUITests/testExample
```

## Building

```bash
# Build for all platforms
swift build

# Build for specific platform (iOS Simulator)
swift build -Xswiftc "-sdk" -Xswiftc "`xcrun --sdk iphonesimulator --show-sdk-path`" -Xswiftc "-target" -Xswiftc "x86_64-apple-ios16.0-simulator"
```

## Dependencies

- [**CornucopiaCore**](https://github.com/Cornucopia-Swift/CornucopiaCore) - Foundation types like `Logger`, `Protected`, and `BusynessObserver`

## Contributing

Contributions are welcome! Feel free to submit issues, feature requests, or pull requests. Please follow the existing code style and include tests for new functionality.

## License

Available under the MIT License. Feel free to use in your projects!