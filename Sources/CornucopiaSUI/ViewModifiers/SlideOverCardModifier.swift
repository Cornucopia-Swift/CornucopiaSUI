//
//  Cornucopia – (C) Dr. Lauer Information Technology
//
#if os(iOS)
import SwiftUI
import UIKit

public struct CC_SlideOverCardOptions: OptionSet {
    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public static let disableDrag = CC_SlideOverCardOptions(rawValue: 1 << 0)
    public static let disableDragToDismiss = CC_SlideOverCardOptions(rawValue: 1 << 1)
    public static let disableTapToDismiss = CC_SlideOverCardOptions(rawValue: 1 << 2)
    public static let hideDismissButton = CC_SlideOverCardOptions(rawValue: 1 << 3)
    public static let hideGrabber = CC_SlideOverCardOptions(rawValue: 1 << 4)

    public static let `default`: CC_SlideOverCardOptions = []
}

public enum CC_SlideOverCardSurfaceStyle {
    case automatic
    case standard
    case glass
}

public enum CC_SlideOverCardPresentationLayout {
    case padded
    case fullWidth
}

public struct CC_SlideOverCardStyle {
    public var cornerRadius: CGFloat
    public var horizontalPadding: CGFloat
    public var verticalPadding: CGFloat
    public var contentPadding: EdgeInsets
    public var maxWidth: CGFloat?
    public var dimmingOpacity: Double
    public var surfaceStyle: CC_SlideOverCardSurfaceStyle
    public var presentationLayout: CC_SlideOverCardPresentationLayout
    public var allowsBackgroundBleeding: Bool
    public var accentTint: Color?

    public init(
        cornerRadius: CGFloat = 30,
        horizontalPadding: CGFloat = 18,
        verticalPadding: CGFloat = 10,
        contentPadding: EdgeInsets = EdgeInsets(top: 26, leading: 20, bottom: 20, trailing: 20),
        maxWidth: CGFloat? = nil,
        dimmingOpacity: Double = 0.32,
        surfaceStyle: CC_SlideOverCardSurfaceStyle = .automatic,
        presentationLayout: CC_SlideOverCardPresentationLayout = .padded,
        allowsBackgroundBleeding: Bool = false,
        accentTint: Color? = nil
    ) {
        self.cornerRadius = cornerRadius
        self.horizontalPadding = horizontalPadding
        self.verticalPadding = verticalPadding
        self.contentPadding = contentPadding
        self.maxWidth = maxWidth
        self.dimmingOpacity = max(0, min(dimmingOpacity, 0.8))
        self.surfaceStyle = surfaceStyle
        self.presentationLayout = presentationLayout
        self.allowsBackgroundBleeding = allowsBackgroundBleeding
        self.accentTint = accentTint
    }

    public static let setup = CC_SlideOverCardStyle()
}

public enum CC_SlideOverCardActionProminence {
    case primary
    case secondary
    case plain
}

public struct CC_SlideOverCardActionButtonStyle: ButtonStyle {
    private let prominence: CC_SlideOverCardActionProminence
    private let tintColor: Color

    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.colorScheme) private var colorScheme

    public init(_ prominence: CC_SlideOverCardActionProminence = .primary, tint: Color = .accentColor) {
        self.prominence = prominence
        self.tintColor = tint
    }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(prominence == .plain ? .regular : .semibold))
            .lineLimit(2)
            .minimumScaleFactor(0.86)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .frame(minHeight: prominence == .plain ? 42 : 52)
            .padding(.horizontal, prominence == .plain ? 4 : 14)
            .foregroundStyle(foregroundColor)
            .background(backgroundShape(isPressed: configuration.isPressed))
            .scaleEffect(configuration.isPressed && prominence != .plain ? 0.985 : 1)
            .opacity(isEnabled ? 1 : 0.45)
            .animation(.easeOut(duration: 0.14), value: configuration.isPressed)
    }

    @ViewBuilder
    private func backgroundShape(isPressed: Bool) -> some View {
        if prominence == .plain {
            Color.clear
        } else {
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .fill(backgroundFill(isPressed: isPressed))
                .overlay {
                    RoundedRectangle(cornerRadius: 15, style: .continuous)
                        .strokeBorder(borderColor, lineWidth: prominence == .primary ? 0 : 0.7)
                }
        }
    }

    private func backgroundFill(isPressed: Bool) -> Color {
        switch prominence {
            case .primary:
                tintColor.opacity(isPressed ? 0.82 : 1)
            case .secondary:
                if colorScheme == .dark {
                    Color.white.opacity(isPressed ? 0.12 : 0.16)
                } else {
                    Color.black.opacity(isPressed ? 0.08 : 0.055)
                }
            case .plain:
                Color.clear
        }
    }

    private var foregroundColor: Color {
        switch prominence {
            case .primary:
                .white
            case .secondary:
                .primary
            case .plain:
                tintColor
        }
    }

    private var borderColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.10) : Color.black.opacity(0.06)
    }
}

public struct CC_SlideOverCardDismissButton: View {
    private let action: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    public init(action: @escaping () -> Void) {
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Image(systemName: "xmark")
                .font(.system(size: 13, weight: .bold))
                .frame(width: 30, height: 30)
                .foregroundStyle(.secondary)
                .contentShape(Circle())
        }
        .buttonStyle(SlideOverCardDismissButtonStyle(colorScheme: colorScheme))
        .accessibilityLabel("Dismiss")
    }
}

private struct SlideOverCardDismissButtonStyle: ButtonStyle {
    let colorScheme: ColorScheme

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(colorScheme == .dark ? 0.06 : 0.42),
                                Color.primary.opacity(colorScheme == .dark ? 0.14 : 0.075)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.26 : 0.08), radius: 8, x: 0, y: 3)
            }
            .overlay {
                Circle()
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(colorScheme == .dark ? 0.09 : 0.56),
                                Color.black.opacity(colorScheme == .dark ? 0.22 : 0.08)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.7
                    )
            }
            .scaleEffect(configuration.isPressed ? 0.92 : 1)
            .animation(.easeOut(duration: 0.10), value: configuration.isPressed)
    }
}

private struct SlideOverCardModifier<CardContent: View>: ViewModifier {
    @Binding var isPresented: Bool
    let style: CC_SlideOverCardStyle
    let options: CC_SlideOverCardOptions
    let onDismiss: (() -> Void)?
    let cardContent: () -> CardContent

    @State private var isHostPresented = false

    func body(content: Content) -> some View {
        content
            .onAppear {
                setHostPresented(isPresented)
            }
            .onChange(of: isPresented) { _, newValue in
                setHostPresented(newValue)
            }
            .fullScreenCover(isPresented: $isHostPresented) {
                SlideOverCardContainer(
                    isPresented: $isPresented,
                    contentID: nil,
                    style: style,
                    options: options,
                    onDismiss: onDismiss,
                    cardContent: cardContent
                )
                .presentationBackground(.clear)
            }
    }

    private func setHostPresented(_ isPresented: Bool) {
        guard isHostPresented != isPresented else { return }

        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            isHostPresented = isPresented
        }
    }
}

private struct SlideOverCardItemModifier<Item: Identifiable, CardContent: View>: ViewModifier {
    @Binding var item: Item?
    let style: CC_SlideOverCardStyle
    let options: CC_SlideOverCardOptions
    let onDismiss: (() -> Void)?
    let cardContent: (Item) -> CardContent

    @State private var isHostPresented = false

    private var isPresented: Binding<Bool> {
        Binding {
            item != nil
        } set: { newValue in
            if !newValue {
                item = nil
            }
        }
    }

    func body(content: Content) -> some View {
        content
            .onAppear {
                setHostPresented(item != nil)
            }
            .onChange(of: item?.id) { _, newValue in
                setHostPresented(newValue != nil)
            }
            .fullScreenCover(isPresented: $isHostPresented) {
                if let item {
                    SlideOverCardContainer(
                        isPresented: isPresented,
                        contentID: AnyHashable(item.id),
                        style: style,
                        options: options,
                        onDismiss: onDismiss
                    ) {
                        cardContent(item)
                    }
                    .presentationBackground(.clear)
                }
            }
    }

    private func setHostPresented(_ isPresented: Bool) {
        guard isHostPresented != isPresented else { return }

        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            isHostPresented = isPresented
        }
    }
}

private struct SlideOverCardContainer<CardContent: View>: View {
    @Binding var isPresented: Bool

    let contentID: AnyHashable?
    let style: CC_SlideOverCardStyle
    let options: CC_SlideOverCardOptions
    let onDismiss: (() -> Void)?
    let cardContent: () -> CardContent

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var showContent = false
    @State private var dragOffset: CGFloat = 0
    @State private var didRequestDismiss = false
    @State private var measuredCardHeight: CGFloat?

    private let minimumPaddedBottomMargin: CGFloat = 16
    private let maximumPaddedSafeAreaContribution: CGFloat = 8

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .bottom) {
                Color.black
                    .opacity(showContent ? style.dimmingOpacity : 0)
                    .ignoresSafeArea(.container)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        guard !options.contains(.disableTapToDismiss) else { return }
                        dismissWithAnimation()
                    }

                if showContent {
                    card(in: proxy)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .ignoresSafeArea(.container)
        .accessibilityAddTraits(.isModal)
        .animation(presentationAnimation, value: showContent)
        .animation(interactionAnimation, value: dragOffset)
        .onAppear {
            withAnimation(presentationAnimation) {
                showContent = true
            }
        }
    }

    private func card(in proxy: GeometryProxy) -> some View {
        let maxWidth = resolvedMaxWidth(for: proxy)
        let extraBottomContentPadding = resolvedBottomContentPadding(for: proxy)

        let card = cardBody(extraBottomContentPadding: extraBottomContentPadding)
            .frame(maxWidth: maxWidth)
            .fixedSize(horizontal: false, vertical: true)
            .readSlideOverCardHeight { height in
                updateMeasuredCardHeight(height)
            }
            .frame(height: measuredCardHeight, alignment: .bottom)
            .clipped()
            .backgroundSurface(style: style, colorScheme: colorScheme)
            .overlay(alignment: .topTrailing) {
                if !options.contains(.hideDismissButton) {
                    CC_SlideOverCardDismissButton {
                        dismissWithAnimation()
                    }
                    .padding(.top, 12)
                    .padding(.trailing, 12)
                }
            }
            .offset(y: dragOffset)
            .padding(.horizontal, resolvedHorizontalPadding(for: proxy))
            .padding(.bottom, resolvedBottomPadding(for: proxy))
            .animation(contentAnimation, value: contentID)
            .animation(contentAnimation, value: measuredCardHeight)
            .accessibilityElement(children: .contain)

        if options.contains(.disableDrag) {
            return AnyView(card)
        } else {
            return AnyView(card.gesture(dragGesture))
        }
    }

    private func cardBody(extraBottomContentPadding: CGFloat) -> some View {
        VStack(spacing: 0) {
            if !options.contains(.hideGrabber) {
                Capsule(style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(colorScheme == .dark ? 0.08 : 0.52),
                                Color.secondary.opacity(colorScheme == .dark ? 0.48 : 0.26),
                                Color.black.opacity(colorScheme == .dark ? 0.20 : 0.05)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 36, height: 5)
                    .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.28 : 0.08), radius: 2, y: 1)
                    .padding(.top, 10)
                    .padding(.bottom, 2)
            }

            cardPayload(extraBottomPadding: extraBottomContentPadding)
        }
    }

    private func cardPayload(extraBottomPadding: CGFloat) -> some View {
        cardContent()
            .id(contentID)
            .transition(.asymmetric(
                insertion: .opacity.combined(with: .scale(scale: 0.985)),
                removal: .opacity
            ))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(
                EdgeInsets(
                    top: style.contentPadding.top,
                    leading: style.contentPadding.leading,
                    bottom: style.contentPadding.bottom + extraBottomPadding,
                    trailing: style.contentPadding.trailing
                )
            )
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 6, coordinateSpace: .global)
            .onChanged { value in
                dragOffset = rubberBandedOffset(value.translation.height)
            }
            .onEnded { value in
                let projectedOffset = value.predictedEndTranslation.height
                let shouldDismiss = !options.contains(.disableDragToDismiss)
                    && (value.translation.height > 92 || projectedOffset > 170)

                if shouldDismiss {
                    dismissWithAnimation()
                } else {
                    withAnimation(interactionAnimation) {
                        dragOffset = 0
                    }
                }
            }
    }

    private func dismissWithAnimation() {
        guard !didRequestDismiss else { return }
        didRequestDismiss = true

        withAnimation(presentationAnimation) {
            showContent = false
            dragOffset = 0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + dismissDelay) {
            isPresented = false
            onDismiss?()
        }
    }

    private func updateMeasuredCardHeight(_ height: CGFloat) {
        guard height > 0 else { return }

        if let measuredCardHeight {
            guard abs(measuredCardHeight - height) > 0.5 else { return }

            withAnimation(contentAnimation) {
                self.measuredCardHeight = height
            }
        } else {
            measuredCardHeight = height
        }
    }

    private func rubberBandedOffset(_ rawOffset: CGFloat) -> CGFloat {
        if rawOffset >= 0 {
            rawOffset
        } else {
            max(rawOffset * 0.16, -18)
        }
    }

    private func resolvedMaxWidth(for proxy: GeometryProxy) -> CGFloat {
        if let maxWidth = style.maxWidth {
            return maxWidth
        }

        if style.presentationLayout == .fullWidth {
            return .infinity
        }

        if horizontalSizeClass == .regular || proxy.size.width >= 700 {
            return 468
        }

        return .infinity
    }

    private func resolvedHorizontalPadding(for proxy: GeometryProxy) -> CGFloat {
        if style.presentationLayout == .fullWidth {
            return 0
        }

        if horizontalSizeClass == .regular || proxy.size.width >= 700 {
            return max(style.horizontalPadding, 24)
        }

        return style.horizontalPadding
    }

    private func resolvedVerticalPadding(for proxy: GeometryProxy) -> CGFloat {
        if style.presentationLayout == .fullWidth {
            return 0
        }

        if horizontalSizeClass == .regular || proxy.size.width >= 700 {
            return max(style.verticalPadding, 24)
        }

        return style.verticalPadding
    }

    private func resolvedBottomPadding(for proxy: GeometryProxy) -> CGFloat {
        if style.presentationLayout == .fullWidth {
            return 0
        }

        let bottomSafeArea = max(proxy.safeAreaInsets.bottom, windowSafeAreaInsets.bottom)
        return max(
            minimumPaddedBottomMargin,
            resolvedVerticalPadding(for: proxy) + min(bottomSafeArea, maximumPaddedSafeAreaContribution)
        )
    }

    private func resolvedBottomContentPadding(for proxy: GeometryProxy) -> CGFloat {
        if style.presentationLayout == .fullWidth {
            return max(proxy.safeAreaInsets.bottom, windowSafeAreaInsets.bottom)
        }

        return 0
    }

    private var windowSafeAreaInsets: UIEdgeInsets {
        let windows = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)

        guard !windows.isEmpty else {
            return .zero
        }

        return windows.reduce(.zero) { result, window in
            UIEdgeInsets(
                top: max(result.top, window.safeAreaInsets.top),
                left: max(result.left, window.safeAreaInsets.left),
                bottom: max(result.bottom, window.safeAreaInsets.bottom),
                right: max(result.right, window.safeAreaInsets.right)
            )
        }
    }

    private var presentationAnimation: Animation {
        reduceMotion ? .linear(duration: 0.01) : .spring(response: 0.42, dampingFraction: 0.86, blendDuration: 0.08)
    }

    private var interactionAnimation: Animation {
        reduceMotion ? .linear(duration: 0.01) : .interactiveSpring(response: 0.30, dampingFraction: 0.88, blendDuration: 0.04)
    }

    private var contentAnimation: Animation {
        reduceMotion ? .linear(duration: 0.01) : .smooth(duration: 0.22)
    }

    private var dismissDelay: TimeInterval {
        reduceMotion ? 0.02 : 0.28
    }
}

private extension View {
    func readSlideOverCardHeight(_ onChange: @escaping (CGFloat) -> Void) -> some View {
        background {
            GeometryReader { proxy in
                Color.clear
                    .preference(key: SlideOverCardHeightPreferenceKey.self, value: proxy.size.height)
            }
        }
        .onPreferenceChange(SlideOverCardHeightPreferenceKey.self, perform: onChange)
    }

    @ViewBuilder
    func backgroundSurface(style: CC_SlideOverCardStyle, colorScheme: ColorScheme) -> some View {
        let bottomRadius = style.presentationLayout == .fullWidth ? 0 : style.cornerRadius
        let shape = UnevenRoundedRectangle(
            cornerRadii: RectangleCornerRadii(
                topLeading: style.cornerRadius,
                bottomLeading: bottomRadius,
                bottomTrailing: bottomRadius,
                topTrailing: style.cornerRadius
            ),
            style: .continuous
        )
        let tint = style.accentTint ?? .accentColor

        switch style.surfaceStyle {
            case .glass where style.allowsBackgroundBleeding:
                if #available(iOS 26.0, *) {
                    self
                        .background {
                            shape.fill(tint.opacity(colorScheme == .dark ? 0.07 : 0.04))
                        }
                        .glassEffect(.regular.tint(tint.opacity(0.055)), in: shape)
                        .clipShape(shape)
                        .slideOverCardShadow(colorScheme: colorScheme)
                } else {
                    self
                        .background {
                            materialSurface(shape: shape, tint: tint, colorScheme: colorScheme)
                        }
                        .clipShape(shape)
                        .slideOverCardShadow(colorScheme: colorScheme)
                }
            case .automatic, .standard, .glass:
                self
                    .background {
                        standardSurface(shape: shape, tint: tint, colorScheme: colorScheme)
                    }
                    .clipShape(shape)
                    .slideOverCardShadow(colorScheme: colorScheme)
        }
    }

    private func slideOverCardShadow(colorScheme: ColorScheme) -> some View {
        self
            .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.50 : 0.18), radius: 34, y: 18)
            .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.22 : 0.08), radius: 8, y: 2)
    }

    private func materialSurface(
        shape: UnevenRoundedRectangle,
        tint: Color,
        colorScheme: ColorScheme
    ) -> some View {
        shape
            .fill(.regularMaterial)
            .overlay {
                shape.fill(tint.opacity(colorScheme == .dark ? 0.08 : 0.04))
            }
            .overlay {
                shape.strokeBorder(surfaceBorder(colorScheme: colorScheme), lineWidth: 0.8)
            }
    }

    private func standardSurface(
        shape: UnevenRoundedRectangle,
        tint: Color,
        colorScheme: ColorScheme
    ) -> some View {
        shape
            .fill(Color(.secondarySystemGroupedBackground))
            .overlay {
                shape.fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(colorScheme == .dark ? 0.05 : 0.30),
                            Color.clear,
                            tint.opacity(colorScheme == .dark ? 0.07 : 0.03)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            }
            .overlay {
                shape.strokeBorder(surfaceBorder(colorScheme: colorScheme), lineWidth: 0.8)
            }
    }

    private func surfaceBorder(colorScheme: ColorScheme) -> LinearGradient {
        LinearGradient(
            colors: [
                Color.white.opacity(colorScheme == .dark ? 0.14 : 0.65),
                Color.black.opacity(colorScheme == .dark ? 0.30 : 0.08)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

private struct SlideOverCardHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

public extension View {
    func CC_slideOverCard<CardContent: View>(
        isPresented: Binding<Bool>,
        style: CC_SlideOverCardStyle = .setup,
        options: CC_SlideOverCardOptions = .default,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: @escaping () -> CardContent
    ) -> some View {
        modifier(
            SlideOverCardModifier(
                isPresented: isPresented,
                style: style,
                options: options,
                onDismiss: onDismiss,
                cardContent: content
            )
        )
    }

    func CC_slideOverCard<Item: Identifiable, CardContent: View>(
        item: Binding<Item?>,
        style: CC_SlideOverCardStyle = .setup,
        options: CC_SlideOverCardOptions = .default,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: @escaping (Item) -> CardContent
    ) -> some View {
        modifier(
            SlideOverCardItemModifier(
                item: item,
                style: style,
                options: options,
                onDismiss: onDismiss,
                cardContent: content
            )
        )
    }
}
#endif
