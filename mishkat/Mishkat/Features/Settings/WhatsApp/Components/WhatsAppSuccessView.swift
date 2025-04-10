import SwiftUI

struct WhatsAppSuccessView: View {
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 32) {
            SuccessIcon()
            
            VStack(spacing: 8) {
                Text("WhatsApp Connected!")
                    .font(.title2)
                    .bold()
                
                Text("Your WhatsApp account is now connected")
                    .foregroundStyle(.secondary)
            }
            
            FeaturesList()
            
            OButton(label: "Done") {
                onDismiss()
            }
        }
    }
}

private struct SuccessIcon: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.green.opacity(0.1))
                .frame(width: 120, height: 120)
            
            Circle()
                .fill(Color.green.opacity(0.2))
                .frame(width: 90, height: 90)
            
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundColor(.green)
        }
        .entranceAnimation()
    }
}

private struct FeaturesList: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("What's Next?")
                .font(.headline)
                .padding(.bottom, 4)
            
            featureRow(
                icon: "calendar.badge.plus",
                title: "Event Detection",
                description: "We'll start detecting events from your messages"
            )
            
            featureRow(
                icon: "bell.badge",
                title: "Smart Notifications",
                description: "Get notified about important events and updates"
            )
            
            featureRow(
                icon: "arrow.triangle.2.circlepath",
                title: "Real-time Sync",
                description: "Your events will stay in sync with WhatsApp"
            )
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.green.opacity(0.1))
        )
        .entranceAnimation(delay: 0.2)
    }
    
    private func featureRow(icon: String, title: String, description: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.green)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
} 