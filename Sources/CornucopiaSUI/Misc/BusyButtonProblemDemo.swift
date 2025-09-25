//
//  Cornucopia – (C) Dr. Lauer Information Technology
//
import SwiftUI

#if DEBUG

/// This demonstrates why a traditional ViewModifier approach doesn't work for buttons
struct BusyButtonProblemDemo: View {
    @State private var isBusyProblem = false
    @State private var isBusyWorking = false
    @State private var buttonTapCount = 0
    @State private var modifierActionCount = 0

    var body: some View {
        VStack(spacing: 40) {
            Text("Button Modifier Problem Demo")
                .font(.title)

            // PROBLEM: Traditional ViewModifier approach
            VStack(spacing: 10) {
                Text("❌ Problem: ViewModifier on existing Button")
                    .font(.headline)

                // This button has its own action that will ALWAYS run
                Button {
                    buttonTapCount += 1
                    print("DEBUG: Button's original action executed")
                } label: {
                    Text("Tap me (Count: \(buttonTapCount))")
                }
                .buttonStyle(.borderedProminent)
                // This modifier CANNOT intercept the button's action!
                // It can only add additional behavior on top
                .modifier(ProblematicBusyModifier(
                    isBusy: $isBusyProblem,
                    action: {
                        modifierActionCount += 1
                        print("DEBUG: Modifier action executed")
                        try await Task.sleep(nanoseconds: NSEC_PER_SEC * 2)
                    }
                ))

                Text("Button taps: \(buttonTapCount), Modifier actions: \(modifierActionCount)")
                    .font(.caption)

                Text("Problem: Both actions run, can't replace button action!")
                    .font(.caption)
                    .foregroundColor(.red)
            }
            .padding()
            .background(Color.red.opacity(0.1))
            .cornerRadius(10)

            Divider()

            // SOLUTION: Wrapper approach
            VStack(spacing: 10) {
                Text("✅ Solution: Wrapper creates the button")
                    .font(.headline)

                // This is NOT a button - it's just a view that gets wrapped
                Text("Process Data")
                    .CC_busyButton(isBusy: $isBusyWorking) {
                        print("DEBUG: Single controlled action")
                        try await Task.sleep(nanoseconds: NSEC_PER_SEC * 2)
                    }
                    .buttonStyle(.borderedProminent)

                Text("Only one action, fully controlled!")
                    .font(.caption)
                    .foregroundColor(.green)
            }
            .padding()
            .background(Color.green.opacity(0.1))
            .cornerRadius(10)
        }
        .padding()
    }
}

/// Problematic modifier that tries to add busy behavior to existing buttons
struct ProblematicBusyModifier: ViewModifier {
    @Binding var isBusy: Bool
    let action: () async throws -> Void

    func body(content: Content) -> some View {
        ZStack {
            content
                .opacity(isBusy ? 0.3 : 1)
                .disabled(isBusy)
                // This tap gesture competes with the button's own action!
                .onTapGesture {
                    guard !isBusy else { return }
                    withAnimation {
                        isBusy = true
                    }
                    Task {
                        defer {
                            DispatchQueue.main.async {
                                withAnimation {
                                    isBusy = false
                                }
                            }
                        }
                        try await action()
                    }
                }

            if isBusy {
                ProgressView()
            }
        }
    }
}

#Preview("Button Modifier Problem") {
    BusyButtonProblemDemo()
}

#endif