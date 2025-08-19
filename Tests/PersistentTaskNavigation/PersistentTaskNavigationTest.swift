//
//  PersistentTaskNavigationTest.swift
//  CornucopiaSUI
//
//  Comprehensive test to verify CC_task behavior during navigation
//
import SwiftUI
import CornucopiaCore

private let logger = Cornucopia.Core.Logger()

public struct PersistentTaskNavigationTest: View {
    @StateObject private var navigationController = NavigationController()
    
    public init() {}
    
    public var body: some View {
        NavigationStack(path: $navigationController.path) {
            RootTestView()
                .navigationDestination(for: TestDestination.self) { destination in
                    switch destination {
                    case .level1:
                        Level1TestView()
                    case .level2:
                        Level2TestView()
                    case .level3:
                        Level3TestView()
                    }
                }
        }
        .environment(\.CC_navigationController, navigationController)
    }
}

enum TestDestination: String, Hashable, CaseIterable {
    case level1 = "Level 1"
    case level2 = "Level 2" 
    case level3 = "Level 3"
}

struct RootTestView: View {
    @Environment(\.CC_navigationController) var navigationController
    @State private var taskId = UUID()
    
    var body: some View {
        VStack(spacing: 20) {
            Text("PersistentTask Navigation Test")
                .font(.title)
                .padding()
            
            Text("Root View")
                .font(.headline)
            
            Text("Check console for task lifecycle logs")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Button("Push to Level 1") {
                navigationController?.push(TestDestination.level1)
            }
            .buttonStyle(.borderedProminent)
            
            Text("Task ID: \(taskId.uuidString.prefix(8))")
                .font(.caption)
                .monospaced()
        }
        .padding()
        .navigationTitle("Root")
        .CC_task {
            let taskName = "ROOT_TASK"
            let shortId = String(taskId.uuidString.prefix(8))
            logger.info("\(taskName)_\(shortId): STARTED")
            
            var counter = 0
            while !Task.isCancelled {
                counter += 1
                logger.trace("\(taskName)_\(shortId): Running iteration \(counter)")
                try? await Task.sleep(for: .seconds(2))
            }
            
            logger.info("\(taskName)_\(shortId): CANCELLED after \(counter) iterations")
        }
        .onAppear {
            logger.info("ROOT_VIEW: onAppear")
        }
        .onDisappear {
            logger.info("ROOT_VIEW: onDisappear")
        }
    }
}

struct Level1TestView: View {
    @Environment(\.CC_navigationController) var navigationController
    @State private var taskId = UUID()
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Level 1 View")
                .font(.headline)
            
            VStack(spacing: 10) {
                Button("Push to Level 2") {
                    navigationController?.push(TestDestination.level2)
                }
                .buttonStyle(.borderedProminent)
                
                Button("Pop to Root") {
                    navigationController?.pop()
                }
                .buttonStyle(.bordered)
            }
            
            Text("Task ID: \(taskId.uuidString.prefix(8))")
                .font(.caption)
                .monospaced()
            
            Spacer()
        }
        .padding()
        .navigationTitle("Level 1")
        .CC_task {
            let taskName = "LEVEL1_TASK"
            let shortId = String(taskId.uuidString.prefix(8))
            logger.info("\(taskName)_\(shortId): STARTED")
            
            var counter = 0
            while !Task.isCancelled {
                counter += 1
                logger.trace("\(taskName)_\(shortId): Running iteration \(counter)")
                try? await Task.sleep(for: .seconds(1.5))
            }
            
            logger.info("\(taskName)_\(shortId): CANCELLED after \(counter) iterations")
        }
        .onAppear {
            logger.info("LEVEL1_VIEW: onAppear")
        }
        .onDisappear {
            logger.info("LEVEL1_VIEW: onDisappear")
        }
    }
}

struct Level2TestView: View {
    @Environment(\.CC_navigationController) var navigationController
    @State private var taskId = UUID()
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Level 2 View")
                .font(.headline)
            
            VStack(spacing: 10) {
                Button("Push to Level 3") {
                    navigationController?.push(TestDestination.level3)
                }
                .buttonStyle(.borderedProminent)
                
                Button("Pop to Level 1") {
                    navigationController?.pop()
                }
                .buttonStyle(.bordered)
                
                Button("Pop to Root") {
                    navigationController?.pop(2)
                }
                .buttonStyle(.bordered)
            }
            
            Text("Task ID: \(taskId.uuidString.prefix(8))")
                .font(.caption)
                .monospaced()
            
            Spacer()
        }
        .padding()
        .navigationTitle("Level 2")
        .CC_task {
            let taskName = "LEVEL2_TASK"
            let shortId = String(taskId.uuidString.prefix(8))
            logger.info("\(taskName)_\(shortId): STARTED")
            
            var counter = 0
            while !Task.isCancelled {
                counter += 1
                logger.trace("\(taskName)_\(shortId): Running iteration \(counter)")
                try? await Task.sleep(for: .seconds(1))
            }
            
            logger.info("\(taskName)_\(shortId): CANCELLED after \(counter) iterations")
        }
        .onAppear {
            logger.info("LEVEL2_VIEW: onAppear")
        }
        .onDisappear {
            logger.info("LEVEL2_VIEW: onDisappear")
        }
    }
}

struct Level3TestView: View {
    @Environment(\.CC_navigationController) var navigationController
    @State private var taskId = UUID()
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Level 3 View")
                .font(.headline)
            
            Text("Deepest level")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            VStack(spacing: 10) {
                Button("Pop to Level 2") {
                    navigationController?.pop()
                }
                .buttonStyle(.bordered)
                
                Button("Pop to Level 1") {
                    navigationController?.pop(2)
                }
                .buttonStyle(.bordered)
                
                Button("Pop to Root") {
                    navigationController?.popToRoot()
                }
                .buttonStyle(.bordered)
            }
            
            Text("Task ID: \(taskId.uuidString.prefix(8))")
                .font(.caption)
                .monospaced()
            
            Spacer()
        }
        .padding()
        .navigationTitle("Level 3")
        .CC_task {
            let taskName = "LEVEL3_TASK"
            let shortId = String(taskId.uuidString.prefix(8))
            logger.info("\(taskName)_\(shortId): STARTED")
            
            var counter = 0
            while !Task.isCancelled {
                counter += 1
                logger.trace("\(taskName)_\(shortId): Running iteration \(counter)")
                try? await Task.sleep(for: .milliseconds(800))
            }
            
            logger.info("\(taskName)_\(shortId): CANCELLED after \(counter) iterations")
        }
        .onAppear {
            logger.info("LEVEL3_VIEW: onAppear")
        }
        .onDisappear {
            logger.info("LEVEL3_VIEW: onDisappear")
        }
    }
}

#Preview("PersistentTask Navigation Test") {
    PersistentTaskNavigationTest()
}