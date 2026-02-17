# CornucopiaSUI

_🐚 The "horn of plenty" – a symbol of abundance._

A SwiftUI utility library that extends the Cornucopia ecosystem with reusable components, view modifiers, and tools for building polished SwiftUI applications across all Apple platforms.

## Platform Support

- iOS 17+
- macOS 13+
- tvOS 17+
- watchOS 10+

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
- **`CC_notificationCapsule`** - Notification capsule for transient messages and activity indicators
- **`CC_confirmationDialog`** - Custom confirmation dialogs with rich styling (iOS)
- **`CC_busyButton`** - Wrap any view as a busy-state button
- **`CC_task`** - Persistent background tasks that survive view hierarchy changes
- **`CC_debouncedTask`** - Debounced task execution
- **`CC_onFirstAppear`** - Execute code only on first view appearance
- **`CC_blendingSyncGroup`** - Synchronize blending animations across a view subtree
- **`CC_blinking`** - Blinking animation effects (hard or soft style)
- **`CC_onCondition`** - Conditional view modification
- **`CC_measureSize`** - Measure view dimensions
- **`CC_withInvisibleNavigation`** - Programmatic navigation without visible links
- **`CC_presentationDetentAutoHeight`** - Auto-sizing sheet presentation
- **`CC_debugPrinting`** - Debug printing for development

### 📱 Views & Components
- **`BusyButton`** / **`GenericBusyButton`** - Buttons with built-in loading states and multiple indicator styles
- **`ConfirmationBusyButton`** - Busy button with built-in confirmation dialog
- **`StyledTextField`** - Pre-styled text fields for common input types (username, password, email, etc.) (iOS)
- **`MarqueeScrollView`** - Generic auto-scrolling container for any SwiftUI content
- **`MarqueeText`** - Smoothly scrolling text for long content
- **`BlendingTextLabel`** - Text with blending animations
- **`SynchronizedBlendingTextLabel`** - Blended text synchronized across a group
- **`SynchronizedBlendingContainer`** - Generic container with synchronized blending
- **`NetworkAwareTextField`** - Text fields with network input validation (hostname, IPv4, IPv6, MAC)
- **`VINTextField`** - Vehicle Identification Number input with validation and formatting
- **`SingleAxisGeometryReader`** - Geometry reading for single axis
- **`ImagePickerView`** - UIKit image picker integration (iOS)

### 🧭 Navigation
- **`NavigationController`** - Type-safe navigation stack management with programmatic control

### 🔧 Observable Tools
- **`NotificationCapsuleController`** - Programmatic control for notification capsule messages
- **`ObservableBusyness`** - Debounced busy state management
- **`ObservableReachability`** - Network connectivity monitoring
- **`ObservableLocalNetworkAuthorization`** - Local network permission state
- **`BlendingSyncManager`** / **`BlendingSyncGroup`** - Centralized synchronization for blending animations

### 🎵 Audio & Media
- **`AudioPlayer`** - Simple audio playback utilities
- **`DevicePickerView`** - Audio route picker (iOS)

### 📱 UIKit Integrations
- **`KeyboardAwareness`** - Keyboard state monitoring
- **`UIImage+Resize`** - Image resizing extensions
- **`UIApplication+AsyncIdleTimer`** - Async idle timer utilities

### 🎨 Extensions
- **Color+ForeignFrameworkColors** - Color compatibility helpers
- **Image+ForeignFrameworks** - Image framework integrations
- **ProcessInfo+Previews** - Preview environment helpers

## Usage Examples

### NotificationCapsule - Transient Messages & Activity Indicators

A capsule-shaped notification overlay anchored at the top of your view. Supports transient notifications (auto-dismiss) and persistent activity indicators (manual dismiss). Each style has a distinct tint color and icon.

```swift
import SwiftUI
import CornucopiaSUI

struct ContentView: View {
    @StateObject private var notifications = NotificationCapsuleController()

    var body: some View {
        NavigationStack {
            MyView()
        }
        .CC_notificationCapsule(notifications)
        .task {
            // Transient messages auto-dismiss after 3 seconds (default)
            notifications.show("Settings saved!", style: .success)

            // Custom duration
            notifications.show("Check your connection", style: .warning, duration: 5.0)

            // Activity indicator stays until explicitly dismissed
            notifications.show("Syncing data\u{2026}", style: .activity)
            await performSync()
            notifications.show("Sync complete!", style: .success)
        }
    }
}
```

Available styles: `.info` (accent), `.success` (green), `.warning` (orange), `.error` (red), `.activity` (spinner).

Successive calls to `show()` replace the current message with a smooth animation. The `.activity` style defaults to persistent display (no auto-dismiss) unless an explicit `duration` is passed.

### ConfirmationDialog - Custom Styled Dialogs (iOS)

```swift
import SwiftUI
import CornucopiaSUI

struct SettingsView: View {
    @State private var showDeleteDialog = false

    var body: some View {
        Button("Delete All Data") { showDeleteDialog = true }
            .CC_confirmationDialog(
                "Clear Data",
                isPresented: $showDeleteDialog,
                actions: [
                    ConfirmationDialogAction("Yes, Delete Everything", role: .destructive) {
                        DataStore.shared.deleteAll()
                    }
                ],
                message: "This will permanently delete all data. This action cannot be undone."
            )
    }
}
```

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

### MarqueeScrollView - Generic Auto-Scrolling Container

```swift
import SwiftUI
import CornucopiaSUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 20) {
            // Any SwiftUI content can scroll
            MarqueeScrollView {
                Label("Long configuration settings text", systemImage: "gear")
            }
            .frame(width: 200)
            
            // Complex layouts work too
            MarqueeScrollView(startDelay: 1.0) {
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                    Text("★★★★★ Excellent product with amazing reviews!")
                        .bold()
                }
            }
            .frame(width: 250)
        }
    }
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

### SynchronizedBlendingTextLabel - Sync Blending Across Views

Synchronize the text-blending animation of multiple labels, independent of when each view appears. Wrap a subtree with `CC_blendingSyncGroup`, then use `SynchronizedBlendingTextLabel` inside it.

```swift
import SwiftUI
import CornucopiaSUI

struct StatusRow: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // These two labels will advance in lockstep
            SynchronizedBlendingTextLabel(["Loading", "Processing", "Working"], duration: 1.5)
            SynchronizedBlendingTextLabel(["Please wait", "Almost there", "Finalizing"], duration: 1.5)
        }
        .CC_blendingSyncGroup("status", duration: 1.5) // group controls the cadence
    }
}
```

Notes:
- The group’s `duration` controls the cycle timing for all members of that group.
- A `SynchronizedBlendingTextLabel` outside any group automatically falls back to `BlendingTextLabel` and uses its own `duration`.
- Multiple independent groups can coexist:

```swift
HStack(spacing: 24) {
    VStack {
        Text("Fast")
        SynchronizedBlendingTextLabel(["●", "●", "●"], duration: 0.8)
    }
    .CC_blendingSyncGroup("fast", duration: 0.8)

    VStack {
        Text("Slow")
        SynchronizedBlendingTextLabel(["◆", "◆", "◆"], duration: 2.5)
    }
    .CC_blendingSyncGroup("slow", duration: 2.5)
}
```

Tip: See the preview “SynchronizedBlendingTextLabel - Scroll Sync Showcase” for a scroll-heavy example that clearly demonstrates synchronization when rows appear at different times.

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

### VINTextField - Vehicle Identification Number Input

```swift
import SwiftUI
import CornucopiaSUI

struct VehicleEntryView: View {
    @State private var vin = ""
    @State private var validationState: VINTextField.ValidationState = .empty
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            VINTextField($vin, focused: $isFocused, validationState: $validationState)
            
            // Respond to validation state changes
            switch validationState {
            case .valid(let validVin, let components):
                VStack {
                    Text("Valid VIN: \(validVin)")
                        .foregroundColor(.green)
                    if let modelYear = components.modelYear {
                        Text("Model Year: \(modelYear)")
                            .font(.caption)
                    }
                }
            case .invalidCheckDigit:
                Text("VIN contains errors - please verify")
                    .foregroundColor(.red)
            default:
                EmptyView()
            }
        }
        .padding()
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
