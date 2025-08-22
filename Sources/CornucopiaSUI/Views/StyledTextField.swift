//
//  StyledTextField.swift
//  CornucopiaSUI
//
//  A styled text field component with icon, title badge, and color theming
//

#if os(iOS)
import SwiftUI
import SFSafeSymbols

public struct StyledTextField: View {
    @Binding var text: String
    let placeholder: String
    let icon: SFSymbol
    let title: String
    let color: SwiftUI.Color
    var isSecure: Bool = false
    var focused: FocusState<Bool>.Binding? = nil
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with icon and title
            HStack(spacing: 8) {
                Image(systemSymbol: icon)
                    .foregroundStyle(color)
                
                Text(title)
                    .font(.callout.weight(.medium))
                    .foregroundStyle(color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(color.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                
                Spacer()
            }
            
            // Text field
            HStack {
                Group {
                    if isSecure {
                        if let focusedBinding = focused {
                            SecureField(placeholder, text: $text)
                                .focused(focusedBinding)
                        } else {
                            SecureField(placeholder, text: $text)
                        }
                    } else {
                        if let focusedBinding = focused {
                            TextField(placeholder, text: $text)
                                .focused(focusedBinding)
                        } else {
                            TextField(placeholder, text: $text)
                        }
                    }
                }
                #if os(iOS)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)
                #endif
                .font(.system(.body, design: .default))
                
                // Clear button
                if !text.isEmpty {
                    Button {
                        text = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                            .font(.body)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(12)
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(color.opacity(text.isEmpty ? 0.3 : 0.8), lineWidth: 1.5)
            }
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(color.opacity(0.05))
            )
            .animation(.easeInOut(duration: 0.15), value: text.isEmpty)
        }
    }
}

// MARK: - Convenience initializers for common field types

public extension StyledTextField {
    static func username(
        text: Binding<String>,
        placeholder: String = "Username",
        color: SwiftUI.Color = .indigo,
        focused: FocusState<Bool>.Binding? = nil,
        onSubmit: (() -> Void)? = nil
    ) -> some View {
        StyledTextField(
            text: text,
            placeholder: placeholder,
            icon: .person,
            title: "Username",
            color: color,
            focused: focused
        )
        .onSubmit {
            onSubmit?()
        }
    }
    
    static func password(
        text: Binding<String>,
        placeholder: String = "Password",
        color: SwiftUI.Color = .orange,
        focused: FocusState<Bool>.Binding? = nil,
        onSubmit: (() -> Void)? = nil
    ) -> some View {
        StyledTextField(
            text: text,
            placeholder: placeholder,
            icon: .lock,
            title: "Password",
            color: color,
            isSecure: true,
            focused: focused
        )
        .onSubmit {
            onSubmit?()
        }
    }
    
    static func email(
        text: Binding<String>,
        placeholder: String = "Email",
        color: SwiftUI.Color = .blue,
        focused: FocusState<Bool>.Binding? = nil,
        onSubmit: (() -> Void)? = nil
    ) -> some View {
        StyledTextField(
            text: text,
            placeholder: placeholder,
            icon: .envelope,
            title: "Email",
            color: color,
            focused: focused
        )
        #if os(iOS)
        .keyboardType(.emailAddress)
        #endif
        .onSubmit {
            onSubmit?()
        }
    }
    
    static func phoneNumber(
        text: Binding<String>,
        placeholder: String = "Phone Number",
        color: SwiftUI.Color = .green,
        focused: FocusState<Bool>.Binding? = nil,
        onSubmit: (() -> Void)? = nil
    ) -> some View {
        StyledTextField(
            text: text,
            placeholder: placeholder,
            icon: .phone,
            title: "Phone",
            color: color,
            focused: focused
        )
        #if os(iOS)
        .keyboardType(.phonePad)
        #endif
        .onSubmit {
            onSubmit?()
        }
    }
    
    static func url(
        text: Binding<String>,
        placeholder: String = "URL",
        color: SwiftUI.Color = .purple,
        focused: FocusState<Bool>.Binding? = nil,
        onSubmit: (() -> Void)? = nil
    ) -> some View {
        StyledTextField(
            text: text,
            placeholder: placeholder,
            icon: .link,
            title: "URL",
            color: color,
            focused: focused
        )
        #if os(iOS)
        .keyboardType(.URL)
        #endif
        .onSubmit {
            onSubmit?()
        }
    }
}

#endif // os(iOS)