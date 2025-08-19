//
//  TaskLifecycleTest.swift
//  CornucopiaSUI
//
//  Simple test to verify CC_task vs regular task behavior
//
import SwiftUI
import CornucopiaCore

private let logger = Cornucopia.Core.Logger()

public struct TaskLifecycleTest: View {
    @State private var showComparison = false
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                Text("Task Lifecycle Test")
                    .font(.title)
                
                Text("This test compares CC_task vs regular .task behavior during navigation")
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                
                NavigationLink("Start Test", destination: TaskComparisonTestView())
                    .buttonStyle(.borderedProminent)
                
                VStack(alignment: .leading, spacing: 5) {
                    Text("Expected behavior:")
                        .font(.headline)
                    Text("• CC_task continues when view is pushed over")
                        .font(.caption)
                    Text("• CC_task cancels when view is popped")
                        .font(.caption)
                    Text("• Regular task always cancels on disappear")
                        .font(.caption)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Task Test")
        }
    }
}

struct TaskComparisonTestView: View {
    @State private var ccTaskId = UUID()
    @State private var regularTaskId = UUID()
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Both tasks are running")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                    Text("CC_task ID: \(ccTaskId.uuidString.prefix(8))")
                        .font(.caption)
                        .monospaced()
                }
                
                HStack {
                    Circle()
                        .fill(Color.orange)
                        .frame(width: 8, height: 8)
                    Text("Regular task ID: \(regularTaskId.uuidString.prefix(8))")
                        .font(.caption)
                        .monospaced()
                }
            }
            .padding()
            .background(Color.gray.opacity(0.05))
            .cornerRadius(8)
            
            NavigationLink("Push Another View", destination: OverlayTestView())
                .buttonStyle(.borderedProminent)
            
            Text("Navigate forward, then back to see the difference")
                .font(.caption)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .padding()
        .navigationTitle("Task Comparison")
        .navigationBarTitleDisplayMode(.inline)
        .CC_task {
            let taskName = "CC_TASK"
            let shortId = String(ccTaskId.uuidString.prefix(8))
            logger.info("\(taskName)_\(shortId): STARTED")
            
            var counter = 0
            while !Task.isCancelled {
                counter += 1
                logger.debug("\(taskName)_\(shortId): Iteration \(counter)")
                try? await Task.sleep(for: .seconds(1))
            }
            
            logger.info("\(taskName)_\(shortId): CANCELLED after \(counter) iterations")
        }
        .task {
            let taskName = "REGULAR_TASK"
            let shortId = String(regularTaskId.uuidString.prefix(8))
            logger.info("\(taskName)_\(shortId): STARTED")
            
            var counter = 0
            while !Task.isCancelled {
                counter += 1
                logger.debug("\(taskName)_\(shortId): Iteration \(counter)")
                try? await Task.sleep(for: .seconds(1))
            }
            
            logger.info("\(taskName)_\(shortId): CANCELLED after \(counter) iterations")
        }
        .onAppear {
            logger.info("COMPARISON_VIEW: onAppear")
        }
        .onDisappear {
            logger.info("COMPARISON_VIEW: onDisappear")
        }
    }
}

struct OverlayTestView: View {
    @State private var overlayTaskId = UUID()
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Overlay View")
                .font(.headline)
            
            Text("This view is 'on top' of the previous view")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Text("Overlay task ID: \(overlayTaskId.uuidString.prefix(8))")
                .font(.caption)
                .monospaced()
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
            
            Text("Check the logs:\n• CC_task should still be running\n• Regular task should have cancelled")
                .font(.caption)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            Text("Navigate back to see CC_task cancel")
                .font(.caption)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
            
            Spacer()
        }
        .padding()
        .navigationTitle("Overlay")
        .navigationBarTitleDisplayMode(.inline)
        .CC_task {
            let taskName = "OVERLAY_TASK"
            let shortId = String(overlayTaskId.uuidString.prefix(8))
            logger.info("\(taskName)_\(shortId): STARTED")
            
            var counter = 0
            while !Task.isCancelled {
                counter += 1
                logger.trace("\(taskName)_\(shortId): Iteration \(counter)")
                try? await Task.sleep(for: .milliseconds(500))
            }
            
            logger.info("\(taskName)_\(shortId): CANCELLED after \(counter) iterations")
        }
        .onAppear {
            logger.info("OVERLAY_VIEW: onAppear")
        }
        .onDisappear {
            logger.info("OVERLAY_VIEW: onDisappear")
        }
    }
}

#Preview("Task Lifecycle Test") {
    TaskLifecycleTest()
}