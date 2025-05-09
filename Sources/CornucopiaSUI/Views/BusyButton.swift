//
//  Cornucopia – (C) Dr. Lauer Information Technology
//
import SwiftUI

/// A basic button that shows a 'busy' behavior when triggered.
public struct BusyButton: View {

    public typealias ActionFunc = () async throws -> ()

    @Binding var isBusy: Bool
    @State private var title: String
    @State private var action: ActionFunc

    public var body: some View {

        ZStack {

            if self.isBusy {
                button
                    .clipShape(Circle())
            } else {
                button
            }

            ProgressView()
                .opacity(isBusy ? 1 : 0)
                .saturation(-1)
        }
        .animation(.easeInOut, value: isBusy)
    }

    public var button: some View {
        Button(action: {
            withAnimation {
                self.isBusy = true
            }
            Task {
                defer { DispatchQueue.main.async { self.isBusy = false} }
                try await self.action()
            }
        }) {
            Text(title)
                .opacity(isBusy ? 0 : 1)
                //NOTE: This used to be here, but it limits the flexibility of the button, so I have removed it. Please apply this modifier in your code, if you need it.
                //.frame(maxWidth: .infinity)
        }
        .disabled(isBusy)
    }

    public init(isBusy: Binding<Bool>, title: String, action: @escaping ActionFunc) {
        self._isBusy = isBusy
        self.title = title
        self.action = action
    }
}

//MARK: - Example
#if DEBUG
private struct BusyButtonExample: View {

    @State private var isBusy: Bool = false

    var body: some View {

        BusyButton(isBusy: $isBusy, title: "Click Me!") {
            print("I have been clicked!")
            try await Task.sleep(nanoseconds: NSEC_PER_SEC * 2)
            print("done")
        }
        .tint(.green)
        .buttonStyle(.bordered)
        .controlSize(.large)
    }
}

struct BusyButton_Previews: PreviewProvider {

    @State private var isBusy: Bool = true

    static var previews: some View {
        BusyButtonExample()
    }
}
#endif
