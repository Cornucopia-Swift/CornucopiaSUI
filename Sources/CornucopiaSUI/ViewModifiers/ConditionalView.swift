//
//  Cornucopia – (C) Dr. Lauer Information Technology
//
import SwiftUI

/// A conditional view, e.g., for an empty state.
struct ConditionalViewModifier<ViewType: View>: ViewModifier {

    let condition: Bool

    @ViewBuilder let conditionalView: () -> ViewType

    func body(content: Content) -> some View {
        if condition {
            conditionalView()
        } else {
            content
        }
    }
}

extension View {
    /// Shows a dedicated view, if the `condition` applies. Use it for, e.g., an empty state.
    public func CC_onCondition<ConditionalViewType: View>(_ condition: Bool, @ViewBuilder conditionalView: @escaping ()->ConditionalViewType) -> some View {
        self.modifier(ConditionalViewModifier(condition: condition, conditionalView: conditionalView))
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
            .CC_onCondition(objects.isEmpty) {
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

struct ConditionalViewExampleView_Previews: PreviewProvider {
    static var previews: some View {
        ExampleView()
    }
}
