//
//  Cornucopia – (C) Dr. Lauer Information Technology
//
import SwiftUI

#if compiler(>=5.5) && canImport(_Concurrency)
/// A View with a debounced task.
struct DebouncedTaskViewModifier<ID: Equatable>: ViewModifier {

    let id: ID
    let priority: TaskPriority
    let nanoseconds: UInt64
    let task: @Sendable () async -> Void

    init(id: ID,
        priority: TaskPriority = .userInitiated,
        seconds: Float,
        task: @Sendable @escaping () async -> Void
    ) {
        self.id = id
        self.priority = priority
        self.nanoseconds = UInt64(seconds * Float(NSEC_PER_SEC))
        self.task = task
    }

    func body(content: Content) -> some View {
        content.task(id: self.id, priority: self.priority) {
            do {
                try await Task.sleep(nanoseconds: self.nanoseconds)
                await task()
            } catch {
                // Ignore cancellation
            }
        }
    }
}

extension View {
    public func CC_debouncedTask<ID: Equatable>(id: ID,
        priority: TaskPriority = .userInitiated,
        seconds: Float,
        task: @Sendable @escaping () async -> Void
    ) -> some View {
        self.modifier(
            DebouncedTaskViewModifier(id: id, priority: priority, seconds: seconds, task: task)
        )
    }
}

//MARK: - Example
fileprivate struct ExampleView: View {

    @State var i: Int = 0
    @State var j: Int = 0

    var body: some View {

        VStack(spacing: 8) {
            Text("i: \(i)")
            Text("j: \(j)")


            Spacer()

            Button {
                i += 1
            } label: {
                Text("Click Me")
            }
            .CC_debouncedTask(id: i, seconds: 0.5) {
                j += 1
            }
        }
    }
}

struct DebouncedTaskExampleView_Previews: PreviewProvider {
    static var previews: some View {
        ExampleView()
    }
}

#endif
