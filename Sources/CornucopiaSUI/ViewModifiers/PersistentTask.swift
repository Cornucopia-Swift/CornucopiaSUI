//
//  Cornucopia – (C) Dr. Lauer Information Technology
//
import SwiftUI

/// A view modifier that runs a task in the background while the view is "alive".
/// In contrast to the `Task` view modifier, this one does not cancel the task when the view is removed from the view hierarchy, but rather when it is being deallocated.
struct PersistentTaskModifier: ViewModifier {
    let action: @Sendable () async -> Void
    @State private var task: Task<Void, Never>?

    init(action: @escaping @Sendable () async -> Void) {
        self.action = action
    }

    func body(content: Content) -> some View {
        content
            .onAppear {
                if task == nil {
                    task = Task {
                        await action()
                    }
                }
            }
    }
}

// Extension to easily apply the custom modifier
public extension View {
    func CC_task(_ action: @escaping @Sendable () async -> Void) -> some View {
        self.modifier(PersistentTaskModifier(action: action))
    }
}

class TaskViewModel: ObservableObject {

    var task: Task<Void, Never>?

    init(action: @escaping @Sendable () async -> Void) {
        self.task = Task {
            await action()
        }
    }

    deinit {
        self.task?.cancel()
    }
}


#Preview {
    /// Create a navigation stack with three views, so that we can see the effect of the Task being cancelled when the "middle" view is popped
    if #available(iOS 16.0, *) {
        NavigationStack {
            List {
                NavigationLink("First View") {
                    List {
                        NavigationLink("Second View") {
                            Text("Second View")
                        }
                        NavigationLink("Third View") {
                            Text("Third View")
                        }
                    }
                    .CC_task {
                        while !Task.isCancelled {
                            print("Second View: Task running")
                            try? await Task.sleep(for: .seconds(1))
                        }
                        print("Second View: Task cancelled")
                    }
                }
            }
        }
    } else {
        // Fallback on earlier versions
    }
}
