//
//  OButton.swift
//  Muwaqqit
//
//  Created by Human on 19/10/2024.
//

import SwiftUI

enum OButtonStyle {
    case primary   // Filled background (current style)
    case secondary // Outlined
    case ghost     // No background
}

enum OButtonSize {
    case small
    case regular
    case large
    
    var verticalPadding: CGFloat {
        switch self {
        case .small: return 8
        case .regular: return 12
        case .large: return 16
        }
    }
    
    var horizontalPadding: CGFloat {
        switch self {
        case .small: return 16
        case .regular: return 20
        case .large: return 24
        }
    }
    
    var iconSize: CGFloat {
        switch self {
        case .small: return 16
        case .regular: return 20
        case .large: return 24
        }
    }
    
    var fontSize: CGFloat {
        switch self {
        case .small: return 14
        case .regular: return 16
        case .large: return 18
        }
    }
}

struct OButton: View {
    private var label: String
    private var icon: Icons?
    private var action: () -> Void
    private var style: OButtonStyle
    private var size: OButtonSize
    private var isLoading: Bool
    private var isDisabled: Bool
    
    init(
        icon: Icons? = nil,
        label: String,
        style: OButtonStyle = .primary,
        size: OButtonSize = .regular,
        isLoading: Bool = false,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.label = label
        self.style = style
        self.size = size
        self.isLoading = isLoading
        self.isDisabled = isDisabled
        self.action = action
    }
    
    private var foregroundColor: Color {
        switch style {
        case .primary:
            return .white
        case .secondary, .ghost:
            return .accentColor
        }
    }
    
    private var backgroundColor: Color {
        switch style {
        case .primary:
            return .accentColor
        case .secondary, .ghost:
            return .clear
        }
    }
    
    var body: some View {
        Button(action: {
            if !isLoading && !isDisabled {
                action()
            }
        }) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: foregroundColor))
                        .frame(width: size.iconSize, height: size.iconSize)
                } else if let icon = icon {
                    Image(icon)
                        .resizable()
                        .scaledToFit()
                        .frame(width: size.iconSize, height: size.iconSize)
                }
                
                Text(label)
                    .font(.system(size: size.fontSize, weight: .semibold))
            }
            .foregroundStyle(foregroundColor)
            .padding(.vertical, size.verticalPadding)
            .padding(.horizontal, size.horizontalPadding)
            .frame(maxWidth: .infinity)
            .background(backgroundColor)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(
                        style == .secondary ? Color.accentColor : .clear,
                        lineWidth: 1.5
                    )
            )
            .cornerRadius(16)
            .opacity(isDisabled ? 0.6 : 1.0)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Convenience Initializers
extension OButton {
    init(label: String, action: @escaping () -> Void) {
        self.init(label: label, style: .primary, action: action)
    }
    
    init(icon: Icons, label: String, action: @escaping () -> Void) {
        self.init(icon: icon, label: label, style: .primary, action: action)
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 20) {
        OButton(
            icon: .brandGoogle,
            label: "Continue with Google",
            style: .primary,
            action: { print("Primary clicked") }
        )
        
        OButton(
            icon: .brandGoogle,
            label: "Continue with Google",
            style: .secondary,
            action: { print("Secondary clicked") }
        )
        
        OButton(
            icon: .brandGoogle,
            label: "Continue with Google",
            style: .ghost,
            size: .small,
            action: { print("Ghost clicked") }
        )
        
        OButton(
            icon: .brandGoogle,
            label: "Loading State",
            isLoading: true,
            action: { print("Loading clicked") }
        )
        
        OButton(
            icon: .brandGoogle,
            label: "Disabled State",
            isDisabled: true,
            action: { print("Disabled clicked") }
        )
    }
    .padding()
}
