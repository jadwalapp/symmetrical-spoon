import SwiftUI

struct WhatsAppConnectingView: View {
    let pairingCode: String
    let isLoading: Bool
    let canRefreshCode: Bool
    let remainingCooldownTime: Int
    let onRefresh: () -> Void
    let onCopy: () -> Void
    
    var body: some View {
        VStack(spacing: 32) {
            ScanningIcon(isLoading: isLoading)
            
            VStack(spacing: 32) {
                InstructionsHeader(isLoading: isLoading)
                
                WhatsAppCodeDisplay(
                    code: pairingCode,
                    isLoading: isLoading,
                    onCopy: onCopy,
                    onRefresh: onRefresh,
                    canRefresh: canRefreshCode,
                    remainingCooldown: remainingCooldownTime
                )
                
                WhatsAppConnectionSteps()
            }
            .animation(.easeInOut, value: isLoading)
        }
    }
}

private struct ScanningIcon: View {
    let isLoading: Bool
    
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.accentColor.opacity(0.1))
                .frame(width: 120, height: 120)
                .scaleEffect(isLoading ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: isLoading)
            
            Circle()
                .fill(Color.accentColor.opacity(0.15))
                .frame(width: 90, height: 90)
                .scaleEffect(isLoading ? 1.15 : 1.0)
                .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true).delay(0.2), value: isLoading)
            
            Image(systemName: "qrcode.viewfinder")
                .font(.system(size: 64))
                .foregroundColor(.accentColor)
        }
        .entranceAnimation()
    }
}

private struct InstructionsHeader: View {
    let isLoading: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            Text("Enter this code in WhatsApp")
                .font(.title3)
                .bold()
            
            if isLoading {
                HStack(spacing: 8) {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Waiting for connection...")
                }
                .foregroundStyle(.secondary)
                .transition(.opacity)
            }
        }
    }
} 