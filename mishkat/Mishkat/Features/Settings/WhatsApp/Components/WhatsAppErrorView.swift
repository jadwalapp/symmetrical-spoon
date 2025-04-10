import SwiftUI

struct WhatsAppErrorView: View {
    let error: Error
    let isLoading: Bool
    let onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: 32) {
            Image(systemName: "exclamationmark.circle.fill")
                .font(.system(size: 64))
                .foregroundColor(.red)
                .entranceAnimation()
            
            Text("Connection Failed")
                .font(.title2)
                .bold()
                .entranceAnimation(delay: 0.1)
            
            Text(error.localizedDescription)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .entranceAnimation(delay: 0.2)
            
            OButton(
                icon: .rotate,
                label: "Try Again",
                isLoading: isLoading
            ) {
                onRetry()
            }
            .entranceAnimation(delay: 0.3)
        }
    }
} 