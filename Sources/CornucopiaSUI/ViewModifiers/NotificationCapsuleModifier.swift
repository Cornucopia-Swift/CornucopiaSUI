//
//  Cornucopia – (C) Dr. Lauer Information Technology
//
import SwiftUI

struct NotificationCapsuleModifier: ViewModifier {
    @ObservedObject var controller: NotificationCapsuleController

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .top) {
                overlayAnchor
            }
    }

    @ViewBuilder
    private var overlayAnchor: some View {
        if let item = controller.currentItem {
            NotificationCapsule(item: item)
                .id(item.id)
                .transition(
                    .asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .move(edge: .top).combined(with: .opacity)
                    )
                )
                .padding(.top, 4)
                .padding(.horizontal, 16)
        }
    }
}

public extension View {
    func CC_notificationCapsule(_ controller: NotificationCapsuleController) -> some View {
        modifier(NotificationCapsuleModifier(controller: controller))
    }
}
