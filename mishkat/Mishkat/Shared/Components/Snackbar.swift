//
//  Snackbar.swift
//  Mishkat
//
//  Created by Human on 28/12/2024.
//

import SwiftUI

struct SnackbarMessage: Identifiable, Equatable {
    let id = UUID()
    let message: String
    let type: SnackbarType
    let timestamp = Date()
    
    static func == (lhs: SnackbarMessage, rhs: SnackbarMessage) -> Bool {
        lhs.id == rhs.id && lhs.timestamp == rhs.timestamp
    }
}

enum SnackbarType {
    case success
    case info
    case warning
    case error // Add this
    
    var color: Color {
        switch self {
        case .success: return .green
        case .info: return .blue
        case .warning: return .orange
        case .error: return .red
        }
    }
    
    var icon: String {
        switch self {
        case .success: return "checkmark.circle.fill"
        case .info: return "info.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .error: return "exclamationmark.triangle.fill"
        }
    }
}

struct Snackbar: View {
    let message: SnackbarMessage
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: message.type.icon)
                .foregroundColor(message.type.color)
            
            Text(message.message)
                .font(.subheadline)
                .foregroundColor(message.type.color)
                .multilineTextAlignment(.leading)
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(message.type.color.opacity(colorScheme == .dark ? 0.15 : 0.1))
        )
    }
}

struct SnackbarOverlay: ViewModifier {
    @Binding var currentMessage: SnackbarMessage?
    private let autoDismissDelay: TimeInterval = 3
    
    func body(content: Content) -> some View {
        ZStack(alignment: .top) {
            content
            
            if let message = currentMessage {
                VStack {
                    Snackbar(message: message)
                    Spacer()
                }
                .padding(.top, UIApplication.shared.windows.first?.safeAreaInsets.top ?? 0)
                .transition(
                    .asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .move(edge: .top).combined(with: .opacity)
                    )
                )
                .onAppear {
                    autoDismiss()
                }
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: currentMessage)
    }
    
    private func autoDismiss() {
        DispatchQueue.main.asyncAfter(deadline: .now() + autoDismissDelay) {
            withAnimation {
                currentMessage = nil
            }
        }
    }
}

extension View {
    func snackbar(message: Binding<SnackbarMessage?>) -> some View {
        modifier(SnackbarOverlay(currentMessage: message))
    }
}
