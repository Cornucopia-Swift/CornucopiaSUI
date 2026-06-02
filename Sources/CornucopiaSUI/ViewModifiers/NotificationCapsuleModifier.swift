//
//  Cornucopia – (C) Dr. Lauer Information Technology
//
import SwiftUI

struct NotificationCapsuleModifier: ViewModifier {
    @ObservedObject var controller: NotificationCapsuleController

    func body(content: Content) -> some View {
        content
            .overlay {
                ZStack {
                    overlayAnchor
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: controller.currentItem?.alignment ?? .top)
            }
    }

    @ViewBuilder
    private var overlayAnchor: some View {
        if let item = controller.currentItem {
            NotificationCapsule(item: item) {
                controller.dismiss()
            }
                .id(item.id)
                .transition(
                    .asymmetric(
                        insertion: .move(edge: item.position.edge).combined(with: .opacity),
                        removal: .move(edge: item.position.edge).combined(with: .opacity)
                    )
                )
                .padding(item.position.paddingEdge, 4)
                .padding(.horizontal, 16)
        }
    }
}

public extension View {
    func CC_notificationCapsule(_ controller: NotificationCapsuleController) -> some View {
        modifier(NotificationCapsuleModifier(controller: controller))
    }
}

private extension NotificationCapsulePosition {
    var edge: Edge {
        switch self {
            case .top: .top
            case .bottom: .bottom
        }
    }

    var paddingEdge: Edge.Set {
        switch self {
            case .top: .top
            case .bottom: .bottom
        }
    }
}
