import SwiftUI

struct WhatsAppInitialView: View {
    @Environment(\.colorScheme) var colorScheme
    @Binding var phoneNumber: String
    @Binding var isPhoneFieldFocused: Bool
    
    var body: some View {
        VStack(spacing: 32) {
            PhoneNumberInput(
                phoneNumber: $phoneNumber,
                isFocused: $isPhoneFieldFocused
            )
            .padding(.top, 32)
            
            BenefitsSection()
        }
    }
}

private struct PhoneNumberInput: View {
    @Environment(\.colorScheme) var colorScheme
    @Binding var phoneNumber: String
    @Binding var isFocused: Bool
    
    @FocusState private var textFieldIsFocused: Bool

    var body: some View {
        VStack(spacing: 24) {
            HStack(spacing: 12) {
                Image(systemName: "phone.fill")
                    .foregroundColor(.secondary)
                
                TextField(
                    "Enter your WhatsApp phone number",
                    text: $phoneNumber
                )
                .keyboardType(.numberPad)
                .textContentType(.telephoneNumber)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .focused($textFieldIsFocused)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(colorScheme == .dark ? Color.gray.opacity(0.1) : Color.gray.opacity(0.05))
            )
            
            Text("Enter the phone number you use for WhatsApp")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .onChange(of: isFocused) { newValue in
            textFieldIsFocused = newValue
        }
        .onChange(of: textFieldIsFocused) { newValue in
            if isFocused != newValue {
                 isFocused = newValue
            }
        }
        .onAppear {
             textFieldIsFocused = isFocused
        }
    }
}

private struct BenefitsSection: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            benefitRow(
                icon: "calendar.badge.plus",
                title: "Automatic Event Detection",
                description: "We'll automatically detect events from your WhatsApp messages"
            )
            benefitRow(
                icon: "lock.shield",
                title: "Secure Connection",
                description: "Your messages are end-to-end encrypted and never stored"
            )
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colorScheme == .dark ? Color.accentColor.opacity(0.1) : Color.accentColor.opacity(0.05))
        )
    }
    
    private func benefitRow(icon: String, title: String, description: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.accentColor)
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
