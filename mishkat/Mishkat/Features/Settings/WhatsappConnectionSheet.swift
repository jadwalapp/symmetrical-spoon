import SwiftUI

struct WhatsappConnectionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var viewModel: WhatsappViewModel
    @State private var contentHeight: CGFloat = 0
    @State private var showConfetti = false
    
    init(whatsappRepository: WhatsappRepository) {
        _viewModel = StateObject(wrappedValue: WhatsappViewModel(whatsappRepository: whatsappRepository))
    }
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    
                    switch viewModel.connectionState {
                    case .initial:
                        initialSection
                    case .connecting(let pairingCode):
                        connectingSection(pairingCode: pairingCode)
                    case .connected:
                        connectedSection
                    case .failed(let error):
                        failedSection(error: error)
                    }
                }
                .padding(24)
                .background(Color(UIColor.systemBackground))
                .background(
                    GeometryReader { proxy in
                        Color.clear.onAppear {
                            contentHeight = proxy.size.height
                        }
                    }
                )
            }
        }
        .presentationDragIndicator(.visible)
        .presentationDetents([.height(contentHeight)])
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(headerTitle)
                .font(.title3)
                .bold()
            Text(headerSubtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var initialSection: some View {
        VStack(spacing: 24) {
            // Benefits section
            VStack(spacing: 16) {
                benefitRow(
                    icon: "calendar.badge.plus",
                    title: "Automatic Event Creation",
                    description: "We'll scan your messages for events and add them to your calendar"
                )
                benefitRow(
                    icon: "lock.shield",
                    title: "Secure Access",
                    description: "We only read messages, never send or modify them"
                )
                benefitRow(
                    icon: "bell.badge",
                    title: "Smart Notifications",
                    description: "Get reminded about events mentioned in your chats"
                )
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(colorScheme == .dark ? Color.accentColor.opacity(0.1) : Color.accentColor.opacity(0.05))
            )
            
            // Phone number input
            VStack(alignment: .leading, spacing: 8) {
                Text("Enter your WhatsApp number")
                    .font(.headline)
                
                HStack(spacing: 12) {
                    Image(systemName: "phone.fill")
                        .foregroundColor(.secondary)
                    
                    TextField("Phone number with country code", text: $viewModel.phoneNumber)
                        .keyboardType(.phonePad)
                        .textContentType(.telephoneNumber)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(colorScheme == .dark ? Color.gray.opacity(0.1) : Color.gray.opacity(0.05))
                )
                
                Text("Include country code (e.g., +1 for US)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            OButton(
                icon: .brandWhatsapp,
                label: "Connect WhatsApp",
                isDisabled: viewModel.phoneNumber.isEmpty
            ) {
                viewModel.connectWhatsapp()
            }
        }
    }
    
    private func connectingSection(pairingCode: String) -> some View {
        VStack(spacing: 24) {
            Image(systemName: "qrcode.viewfinder")
                .font(.system(size: 48))
                .foregroundColor(.accentColor)
            
            VStack(spacing: 16) {
                Text("Open WhatsApp on your phone")
                    .font(.headline)
                
                Text("1. Open WhatsApp Settings")
                Text("2. Tap Linked Devices")
                Text("3. Tap Link a Device")
                Text("4. Enter this code:")
                
                Text(pairingCode)
                    .font(.system(.title, design: .monospaced))
                    .bold()
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(colorScheme == .dark ? Color.gray.opacity(0.1) : Color.gray.opacity(0.05))
                    )
            }
            .multilineTextAlignment(.center)
        }
    }
    
    private var connectedSection: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundColor(.green)
                .overlay {
                    if showConfetti {
                        ConfettiView()
                    }
                }
            
            Text("WhatsApp Connected!")
                .font(.title2)
                .bold()
            
            Text("We'll now scan your messages for events and add them to your calendar automatically.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            
            OButton(label: "Done") {
                dismiss()
            }
        }
        .onAppear {
            withAnimation {
                showConfetti = true
            }
        }
    }
    
    private func failedSection(error: Error) -> some View {
        VStack(spacing: 24) {
            Image(systemName: "exclamationmark.circle.fill")
                .font(.system(size: 48))
                .foregroundColor(.red)
            
            Text("Connection Failed")
                .font(.title2)
                .bold()
            
            Text(error.localizedDescription)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            
            OButton(
                icon: .rotate,
                label: "Try Again"
            ) {
                viewModel.reset()
            }
        }
    }
    
    private func benefitRow(icon: String, title: String, description: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.accentColor)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    private var headerTitle: String {
        switch viewModel.connectionState {
        case .initial:
            return "Connect WhatsApp"
        case .connecting:
            return "Enter Pairing Code"
        case .connected:
            return "Success!"
        case .failed:
            return "Connection Failed"
        }
    }
    
    private var headerSubtitle: String {
        switch viewModel.connectionState {
        case .initial:
            return "Let us help you manage your events"
        case .connecting:
            return "Follow the steps to connect your account"
        case .connected:
            return "Your WhatsApp is now connected"
        case .failed:
            return "Something went wrong"
        }
    }
}

// Simple confetti view
struct ConfettiView: View {
    let colors: [Color] = [.red, .blue, .green, .yellow, .pink, .purple, .orange]
    
    var body: some View {
        GeometryReader { geometry in
            ForEach(0..<50) { _ in
                Circle()
                    .fill(colors.randomElement()!)
                    .frame(width: 8, height: 8)
                    .position(
                        x: CGFloat.random(in: 0...geometry.size.width),
                        y: CGFloat.random(in: 0...geometry.size.height)
                    )
                    .animation(
                        Animation.interpolatingSpring(stiffness: 0.5, damping: 0.5)
                            .repeatForever()
                            .speed(.random(in: 0.5...1.5))
                            .delay(.random(in: 0...1)),
                        value: UUID()
                    )
            }
        }
    }
} 
