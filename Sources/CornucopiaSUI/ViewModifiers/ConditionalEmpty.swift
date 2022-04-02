//
//  Cornucopia – (C) Dr. Lauer Information Technology
//
import SwiftUI

/// A conditional view, e.g., for an empty state.
struct ConditionalEmptyView<EmptyViewType: View>: ViewModifier {

    let condition: Bool

    @ViewBuilder let emptyView: () -> EmptyViewType

    func body(content: Content) -> some View {
        if condition {
            emptyView()
        } else {
            content
        }
    }
}

extension View {
    func CC_onEmpty<EmptyViewType: View>(for condition: Bool, @ViewBuilder emptyView: @escaping ()->EmptyViewType) -> some View {
        self.modifier(ConditionalEmptyView(condition: condition, emptyView: emptyView))
    }
}

//MARK: - Example

fileprivate struct ExampleView: View {

    @State var objects: [Int] = []

    var body: some View {
        NavigationView {
            List(objects, id: \.self) { obj in
                Text("\(obj)")
            }
            .CC_onEmpty(for: objects.isEmpty) {
                Text("Sorry, no data yet")
                    .font(.title)
                    .foregroundColor(.secondary)
            }
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button("Add") {
                        objects.append(objects.count)
                    }
                    Button("Remove") {
                        objects.removeLast()
                    }
                }
            }
        }
    }
}

struct ExampleView_Previews: PreviewProvider {
    static var previews: some View {
        ExampleView()
    }
}
