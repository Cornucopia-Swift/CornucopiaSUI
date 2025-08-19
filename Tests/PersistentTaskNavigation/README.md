# CornucopiaSUI Task Behavior Tests

This directory contains comprehensive tests to verify the correct behavior of the `CC_task` modifier compared to SwiftUI's regular `.task` modifier.

## Test Files

### TaskLifecycleTest.swift
A simple test comparing `CC_task` vs regular `.task` behavior during navigation.

**Expected Log Output:**
```
COMPARISON_VIEW: onAppear
CC_TASK_12345678: STARTED
REGULAR_TASK_87654321: STARTED
CC_TASK_12345678: Iteration 1
REGULAR_TASK_87654321: Iteration 1
CC_TASK_12345678: Iteration 2
REGULAR_TASK_87654321: Iteration 2
...
COMPARISON_VIEW: onDisappear
REGULAR_TASK_87654321: CANCELLED after 3 iterations  <- Regular task cancels on view disappear
CC_TASK_12345678: Iteration 4                        <- CC_task continues running
OVERLAY_VIEW: onAppear
OVERLAY_TASK_ABCDEF12: STARTED
CC_TASK_12345678: Iteration 5                        <- CC_task still running
OVERLAY_TASK_ABCDEF12: Iteration 1
...
OVERLAY_VIEW: onDisappear                             <- User navigated back
OVERLAY_TASK_ABCDEF12: CANCELLED after 2 iterations  <- Overlay task cancels
COMPARISON_VIEW: onAppear                             <- Original view reappears
CC_TASK_12345678: CANCELLED after 8 iterations       <- CC_task finally cancels when view is popped
```

### PersistentTaskNavigationTest.swift
A comprehensive multi-level navigation test with multiple concurrent CC_tasks.

**Test Scenarios:**
1. **Push Navigation**: Tasks should persist when pushing new views
2. **Pop Navigation**: Tasks should cancel only when their view is popped
3. **Multi-level Pop**: Multiple tasks should cancel when popping multiple levels

**Expected Behavior:**
- When navigating Root → Level1 → Level2 → Level3, all tasks continue running
- When popping Level3 → Level2, only Level3 task cancels
- When popping multiple levels (e.g., Level3 → Root), all intermediate tasks cancel

## How to Use These Tests

### In a SwiftUI Preview
```swift
#Preview {
    TaskLifecycleTest()
}
```

### In an iOS App
Add either test view to your app's ContentView or present as a sheet:
```swift
struct ContentView: View {
    var body: some View {
        TaskLifecycleTest()
    }
}
```

### Reading the Console Logs
1. Run the app in Xcode
2. Open the Console (Cmd+Shift+Y)  
3. Filter for "TASK" or "VIEW" to see relevant logs
4. Navigate through the test interface
5. Observe the task lifecycle logs

## Key Behaviors to Verify

### ✅ Correct CC_task Behavior
- Tasks start when view appears
- Tasks continue running when view is pushed over (disappears but stays in navigation stack)
- Tasks only cancel when view is popped (removed from navigation stack)

### ✅ Regular .task Behavior
- Tasks start when view appears
- Tasks cancel immediately when view disappears (regardless of push/pop)

### ❌ Incorrect Behavior (Would indicate bugs)
- CC_task cancels on push (should persist)
- CC_task doesn't cancel on pop (should cancel)
- Memory leaks from uncancelled tasks

## Log Message Format
- `TASKNAME_SHORTID: STARTED` - Task begins
- `TASKNAME_SHORTID: Iteration N` - Task is actively running
- `TASKNAME_SHORTID: CANCELLED after N iterations` - Task properly cancelled
- `VIEWNAME: onAppear/onDisappear` - View lifecycle events

The short ID (first 8 characters of UUID) helps track individual task instances across the logs.