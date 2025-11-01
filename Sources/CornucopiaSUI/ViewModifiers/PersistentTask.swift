//
//  Cornucopia – (C) Dr. Lauer Information Technology
//
import SwiftUI

/// A view modifier that runs a task in the background while the view is "alive".
/// In contrast to the `Task` view modifier, this one does not cancel the task when the view is temporarily removed from the view hierarchy (e.g., during navigation push), but cancels it when the view is permanently removed (e.g., during navigation pop).
struct PersistentTaskModifier: ViewModifier {
    let action: @Sendable () async -> Void
    @StateObject private var taskManager: TaskViewModel
    
    init(action: @escaping @Sendable () async -> Void) {
        self.action = action
        self._taskManager = StateObject(wrappedValue: TaskViewModel(action: action))
    }

    func body(content: Content) -> some View {
        content
            .onAppear {
                // Task is already started in TaskViewModel.init
                // Nothing needed here since StateObject persists across view hierarchy changes
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


#Preview("PersistentTask - Comprehensive") {
    struct PersistentTaskShowcase: View {
        @State private var navigationPath = NavigationPath()
        @State private var persistentCounter = 0
        @State private var normalCounter = 0
        @State private var showSheet = false
        @State private var persistentLog: [String] = []
        @State private var normalLog: [String] = []
        
        var body: some View {
            if #available(iOS 16.0, *) {
                NavigationStack(path: $navigationPath) {
                    ScrollView {
                        VStack(spacing: 30) {
                            Text("PersistentTask vs Task")
                                .font(.largeTitle)
                                .padding(.bottom)
                            
                            Text("PersistentTask continues running when view is removed from hierarchy\nRegular Task is cancelled immediately")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                            
                            // Navigation example
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Navigation Test")
                                    .font(.headline)
                                
                                NavigationLink("Open View with Tasks") {
                                    TaskComparisonView(
                                        persistentCounter: $persistentCounter,
                                        normalCounter: $normalCounter,
                                        persistentLog: $persistentLog,
                                        normalLog: $normalLog
                                    )
                                }
                                .buttonStyle(.borderedProminent)
                                
                                HStack(spacing: 40) {
                                    VStack(alignment: .leading) {
                                        Text("PersistentTask")
                                            .font(.subheadline)
                                            .bold()
                                        Text("Count: \(persistentCounter)")
                                            .font(.title2)
                                            .foregroundColor(.green)
                                        Text("Continues after pop")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    VStack(alignment: .leading) {
                                        Text("Regular Task")
                                            .font(.subheadline)
                                            .bold()
                                        Text("Count: \(normalCounter)")
                                            .font(.title2)
                                            .foregroundColor(.orange)
                                        Text("Cancels on pop")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(8)
                            }
                            
                            // Sheet example
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Sheet Test")
                                    .font(.headline)
                                
                                Button("Show Sheet with Tasks") {
                                    showSheet = true
                                }
                                .buttonStyle(.bordered)
                                .sheet(isPresented: $showSheet) {
                                    SheetWithTasks()
                                }
                            }
                            
                            // Logs
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Task Logs")
                                    .font(.headline)
                                
                                HStack(alignment: .top, spacing: 20) {
                                    VStack(alignment: .leading) {
                                        Text("PersistentTask Log")
                                            .font(.subheadline)
                                            .foregroundColor(.green)
                                        ScrollView {
                                            VStack(alignment: .leading) {
                                                ForEach(persistentLog.suffix(5), id: \.self) { log in
                                                    Text(log)
                                                        .font(.caption2)
                                                }
                                            }
                                        }
                                        .frame(height: 100)
                                        .frame(maxWidth: .infinity)
                                        .background(Color.green.opacity(0.05))
                                        .cornerRadius(4)
                                    }
                                    
                                    VStack(alignment: .leading) {
                                        Text("Regular Task Log")
                                            .font(.subheadline)
                                            .foregroundColor(.orange)
                                        ScrollView {
                                            VStack(alignment: .leading) {
                                                ForEach(normalLog.suffix(5), id: \.self) { log in
                                                    Text(log)
                                                        .font(.caption2)
                                                }
                                            }
                                        }
                                        .frame(height: 100)
                                        .frame(maxWidth: .infinity)
                                        .background(Color.orange.opacity(0.05))
                                        .cornerRadius(4)
                                    }
                                }
                                
                                Button("Clear Logs") {
                                    persistentLog.removeAll()
                                    normalLog.removeAll()
                                    persistentCounter = 0
                                    normalCounter = 0
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                            }
                        }
                        .padding()
                    }
                    .navigationTitle("PersistentTask Demo")
                }
            } else {
                Text("Requires iOS 16.0+")
            }
        }
    }
    
    struct TaskComparisonView: View {
        @Binding var persistentCounter: Int
        @Binding var normalCounter: Int
        @Binding var persistentLog: [String]
        @Binding var normalLog: [String]
        @State private var localPersistentTask: Task<Void, Never>?
        @State private var viewAppeared = false
        
        var body: some View {
            VStack(spacing: 20) {
                Text("Tasks Running")
                    .font(.title)
                
                Text("Navigate back to see the difference")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                VStack(spacing: 10) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("PersistentTask: \(persistentCounter)")
                            .font(.headline)
                    }
                    
                    HStack {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.orange)
                        Text("Regular Task: \(normalCounter)")
                            .font(.headline)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                
                Text("Both tasks increment every second.\nGo back to see which continues.")
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
            }
            .padding()
            .navigationTitle("Task Comparison")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .CC_task {
                persistentLog.append("[\(Date().formatted(.dateTime.hour().minute().second()))] PersistentTask started")
                while !Task.isCancelled {
                    persistentCounter += 1
                    try? await Task.sleep(for: .seconds(1))
                }
                persistentLog.append("[\(Date().formatted(.dateTime.hour().minute().second()))] PersistentTask cancelled")
            }
            .task {
                normalLog.append("[\(Date().formatted(.dateTime.hour().minute().second()))] Regular task started")
                while !Task.isCancelled {
                    normalCounter += 1
                    try? await Task.sleep(for: .seconds(1))
                }
                normalLog.append("[\(Date().formatted(.dateTime.hour().minute().second()))] Regular task cancelled")
            }
        }
    }
    
    struct SheetWithTasks: View {
        @State private var sheetPersistentCount = 0
        @State private var sheetNormalCount = 0
        @Environment(\.dismiss) private var dismiss
        
        var body: some View {
            VStack(spacing: 20) {
                Text("Sheet with Tasks")
                    .font(.title2)
                    .padding(.top)
                
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("PersistentTask:")
                        Text("\(sheetPersistentCount)")
                            .font(.title3)
                            .foregroundColor(.green)
                    }
                    
                    HStack {
                        Text("Regular Task:")
                        Text("\(sheetNormalCount)")
                            .font(.title3)
                            .foregroundColor(.orange)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                
                Text("Dismiss sheet to see which task continues")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Button("Dismiss") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                
                Spacer()
            }
            .padding()
            .CC_task {
                while !Task.isCancelled {
                    sheetPersistentCount += 1
                    try? await Task.sleep(for: .milliseconds(500))
                }
            }
            .task {
                while !Task.isCancelled {
                    sheetNormalCount += 1
                    try? await Task.sleep(for: .milliseconds(500))
                }
            }
        }
    }
    
    return PersistentTaskShowcase()
}
