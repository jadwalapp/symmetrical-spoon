import SwiftUI

struct WhatsAppCodeDisplay: View {
    @Environment(\.colorScheme) var colorScheme
    let code: String
    let isLoading: Bool
    let onCopy: () -> Void
    let onRefresh: () -> Void
    let canRefresh: Bool
    let remainingCooldown: Int
    
    var body: some View {
        VStack(spacing: 24) {
            let mid = code.count / 2
            let firstHalf = String(code.prefix(mid))
            let secondHalf = String(code.suffix(code.count - mid))
            
            HStack(spacing: 16) {
                codeBox(firstHalf)
                Text("-")
                    .font(.system(.title2, design: .monospaced))
                    .bold()
                    .foregroundStyle(.secondary)
                codeBox(secondHalf)
            }
            .frame(maxWidth: .infinity)
            .id(code)
            
            VStack(spacing: 12) {
                CopyButton(code: code, onCopy: onCopy)
                RefreshButton(
                    canRefresh: canRefresh,
                    isLoading: isLoading,
                    remainingCooldown: remainingCooldown,
                    onRefresh: onRefresh
                )
            }
            .fixedSize(horizontal: false, vertical: true)
        }
        .animation(.none, value: code)
    }
    
    private func codeBox(_ text: String) -> some View {
        Text(text)
            .font(.system(.title, design: .monospaced))
            .bold()
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(colorScheme == .dark ? Color.gray.opacity(0.1) : Color.gray.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.accentColor.opacity(0.2), lineWidth: 1)
                            .scaleEffect(isLoading ? 1.04 : 1.0)
                            .opacity(isLoading ? 0.6 : 0.0)
                    )
            )
            .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: isLoading)
            .id(text)
            .transition(.move(edge: .top).combined(with: .opacity))
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: text)
    }
}

private struct CopyButton: View {
    let code: String
    let onCopy: () -> Void
    @State private var isCopied = false
    
    var body: some View {
        Button(action: {
            UIPasteboard.general.string = code
            isCopied = true
            onCopy()
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    isCopied = false
                }
            }
        }) {
            HStack {
                ZStack {
                    Image(systemName: "doc.on.doc")
                        .opacity(isCopied ? 0 : 1)
                    Image(systemName: "checkmark")
                        .opacity(isCopied ? 1 : 0)
                }
                .font(.title3)
                
                Text(isCopied ? "Copied!" : "Copy Code")
                    .font(.headline)
            }
            .foregroundStyle(isCopied ? Color.green : .primary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
        }
        .buttonStyle(PressableButtonStyle())
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.accentColor.opacity(0.1))
        )
    }
}

private struct RefreshButton: View {
    @Environment(\.colorScheme) var colorScheme
    let canRefresh: Bool
    let isLoading: Bool
    let remainingCooldown: Int
    let onRefresh: () -> Void
    
    var body: some View {
        Button(action: onRefresh) {
            HStack {
                Spacer()
                HStack(spacing: 8) {
                    Image(systemName: "arrow.clockwise")
                        .font(.title3)
                    
                    if !canRefresh {
                        Text("\(remainingCooldown)s")
                            .monospacedDigit()
                    } else {
                        Text("Get New Code")
                    }
                    
                    if !canRefresh {
                        Text("Wait")
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
            }
            .foregroundStyle(.secondary)
            .padding(.horizontal, 4)
            .frame(maxWidth: .infinity)
            .frame(height: 44)
        }
        .buttonStyle(PressableButtonStyle())
        .disabled(!canRefresh || isLoading)
        .opacity(!canRefresh || isLoading ? 0.5 : 1.0)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colorScheme == .dark ? Color.gray.opacity(0.1) : Color.gray.opacity(0.05))
        )
    }
} 