import SwiftUI

struct WhatsAppConnectionSteps: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("How to connect:")
                .font(.headline)
                .foregroundColor(.accentColor)
                .padding(.bottom, 8)
            
            VStack(alignment: .leading, spacing: 20) {
                stepRow(number: 1, text: "Open WhatsApp on your phone")
                stepRow(number: 2, text: "Go to Settings → Linked Devices")
                stepRow(number: 3, text: "Tap 'Link a Device'")
                stepRow(number: 4, text: "Enter the 8-digit code shown above")
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.accentColor.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.accentColor.opacity(0.1), lineWidth: 1)
                )
        )
    }
    
    private func stepRow(number: Int, text: String) -> some View {
        HStack(alignment: .center, spacing: 16) {
            Text("\(number)")
                .font(.headline)
                .foregroundColor(.accentColor)
                .frame(width: 28, height: 28)
                .background(
                    Circle()
                        .fill(Color.accentColor.opacity(0.1))
                )
            
            Text(text)
                .font(.callout)
                .foregroundColor(.primary)
        }
        .contentShape(Rectangle())
    }
} 