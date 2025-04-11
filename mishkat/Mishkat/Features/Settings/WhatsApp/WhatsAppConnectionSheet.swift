import SwiftUI

struct WhatsappConnectionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var viewModel: WhatsappViewModel
    @FocusState private var isPhoneFieldFocused: Bool

    @State private var isCopied = false
    @State private var showCopyToast = false
    @State private var cooldownTimer: Timer?
    @State private var forceUpdate = false
    @State private var animatingCode = false
    @State private var randomizedCode = ""
    private let possibleCharacters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"

    init(whatsappRepository: WhatsappRepository) {
        _viewModel = StateObject(wrappedValue: WhatsappViewModel(whatsappRepository: whatsappRepository))
    }

    private func startCooldownTimer() {
        cooldownTimer?.invalidate()
        cooldownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            withAnimation {
                forceUpdate.toggle()
            }
            if viewModel.canRefreshCode {
                cooldownTimer?.invalidate()
                cooldownTimer = nil
            }
        }
    }

    private func refreshCode() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            viewModel.refreshPairingCode()
        }
        startCooldownTimer()
    }

    private func startCodeAnimation(finalCode: String) {
        animatingCode = true
        var iterationCount = 0
        let maxIterations = 15

        func animate() {
            if iterationCount < maxIterations {
                iterationCount += 1

                // Generate random code of same length
                randomizedCode = String((0..<finalCode.count).map { _ in
                    possibleCharacters.randomElement()!
                })

                // Schedule next animation frame
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    animate()
                }
            } else {
                // Final iteration - show actual code
                randomizedCode = finalCode
                animatingCode = false
            }
        }

        // Start animation
        animate()
    }

    var body: some View {
        NavigationView {
            ZStack(alignment: .bottom) {
                ScrollView {
                    VStack(spacing: 32) {
                        switch viewModel.connectionState {
                        case .initial:
                            initialContent
                        case .connecting(let pairingCode):
                            connectingSection(pairingCode: pairingCode)
                        case .connected:
                            connectedSection
                        case .failed(let error):
                            failedSection(error: error)
                        case .initializing:
                            if let existingCode = viewModel.existingPairingCode {
                                VStack {
                                    connectingSection(pairingCode: existingCode)

                                    // Add a button to force reconnect if stuck
                                    Button {
                                        viewModel.forceReconnect()
                                    } label: {
                                        Label("Start New Session", systemImage: "arrow.triangle.2.circlepath")
                                            .foregroundStyle(.orange)
                                    }
                                    .buttonStyle(PressableButtonStyle())
                                    .padding(.top, -16) // Adjust spacing with the section above
                                }
                            } else {
                                connectingSection(pairingCode: "")
                            }
                        }
                    }
                    .padding(24)
                }

                if case .initial = viewModel.connectionState {
                    connectButton
                }
            }
            .navigationTitle(headerTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(viewModel.isLoading)
                }
            }
        }
        .interactiveDismissDisabled(viewModel.isLoading)
    }

    private var initialContent: some View {
        VStack(spacing: 32) {
            // Phone number input
            VStack(spacing: 24) {
                HStack(spacing: 12) {
                    Image(systemName: "phone.fill")
                        .foregroundColor(.secondary)

                    TextField("Enter WhatsApp number", text: $viewModel.phoneNumber)
                        .keyboardType(.numberPad)
                        .textContentType(.telephoneNumber)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .focused($isPhoneFieldFocused)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(colorScheme == .dark ? Color.gray.opacity(0.1) : Color.gray.opacity(0.05))
                )

                Text("Enter your number in international format (e.g. +966501234567)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 32)

            // Benefits section
            VStack(alignment: .leading, spacing: 24) {
                benefitRow(
                    icon: "calendar.badge.plus",
                    title: "Automatic Event Creation",
                    description: "We'll scan your messages for events"
                )
                benefitRow(
                    icon: "lock.shield",
                    title: "Secure Access",
                    description: "We only read messages, never modify"
                )
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(colorScheme == .dark ? Color.accentColor.opacity(0.1) : Color.accentColor.opacity(0.05))
            )
        }
    }

    private var connectButton: some View {
        VStack(spacing: 0) {
            Divider()

            OButton(
                icon: .brandWhatsapp,
                label: "Connect WhatsApp",
                isLoading: viewModel.isLoading,
                isDisabled: !viewModel.isValidPhoneNumber || viewModel.isLoading
            ) {
                isPhoneFieldFocused = false
                viewModel.connectWhatsapp()
            }
            .padding()
        }
        .background(.background)
    }

    private func connectingSection(pairingCode: String) -> some View {
        VStack(spacing: 32) {
            // Animated icon with breathing effect
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.1))
                    .frame(width: 120, height: 120)
                    .scaleEffect(viewModel.isLoading ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: viewModel.isLoading)

                Circle()
                    .fill(Color.accentColor.opacity(0.15))
                    .frame(width: 90, height: 90)
                    .scaleEffect(viewModel.isLoading ? 1.15 : 1.0)
                    .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true).delay(0.2), value: viewModel.isLoading)

                Image(systemName: "qrcode.viewfinder")
                    .font(.system(size: 64))
                    .foregroundColor(.accentColor)
            }
            .entranceAnimation()

            VStack(spacing: 32) {
                // Instructions
                VStack(spacing: 8) {
                    Text("Enter this code in WhatsApp")
                        .font(.title3)
                        .bold()

                    if viewModel.isLoading {
                        HStack(spacing: 8) {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Waiting for connection...")
                        }
                        .foregroundStyle(.secondary)
                        .transition(.opacity)
                    }
                }

                // Code display
                VStack(spacing: 24) {
                    let mid = pairingCode.count / 2
                    let firstHalf = String(pairingCode.prefix(mid))
                    let secondHalf = String(pairingCode.suffix(pairingCode.count - mid))

                    HStack(spacing: 16) {
                        codeBox(firstHalf, finalText: firstHalf)
                        Text("-")
                            .font(.system(.title2, design: .monospaced))
                            .bold()
                            .foregroundStyle(.secondary)
                        codeBox(secondHalf, finalText: secondHalf)
                    }
                    .frame(maxWidth: .infinity)
                    .id(pairingCode) // Force view recreation on code change

                    VStack(spacing: 12) {
                        // Copy button
                        Button {
                            UIPasteboard.general.string = pairingCode
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                isCopied = true
                                showCopyToast = true
                            }
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()

                            // Reset after delay
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                    isCopied = false
                                    showCopyToast = false
                                }
                            }
                        } label: {
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

                        // Reset button
                        Button {
                            refreshCode()
                        } label: {
                            HStack {
                                Spacer()
                                HStack(spacing: 8) {
                                    Image(systemName: "arrow.clockwise")
                                        .font(.title3)
                                        .rotationEffect(.degrees(forceUpdate ? 0 : 0))

                                    if !viewModel.canRefreshCode {
                                        Text("\(viewModel.remainingCooldownTime)s")
                                            .monospacedDigit()
                                    } else {
                                        Text("Get New Code")
                                    }

                                    if !viewModel.canRefreshCode {
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
                        .disabled(!viewModel.canRefreshCode || viewModel.isLoading)
                        .opacity(!viewModel.canRefreshCode || viewModel.isLoading ? 0.5 : 1.0)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(colorScheme == .dark ? Color.gray.opacity(0.1) : Color.gray.opacity(0.05))
                        )
                    }
                    .fixedSize(horizontal: false, vertical: true)
                }
                .animation(.none, value: pairingCode)

                // Steps
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
            .animation(.easeInOut, value: viewModel.isLoading)
        }
    }

    private func codeBox(_ text: String, finalText: String) -> some View {
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
                            .scaleEffect(viewModel.isLoading ? 1.04 : 1.0)
                            .opacity(viewModel.isLoading ? 0.6 : 0.0)
                    )
            )
            .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: viewModel.isLoading)
            .id(text) // Force view recreation for animation
            .transition(.move(edge: .top).combined(with: .opacity))
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: text)
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

    private var connectedSection: some View {
        VStack(spacing: 32) {
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

            VStack(spacing: 8) {
                Text("WhatsApp Connected!")
                    .font(.title2)
                    .bold()

                Text("Your account is ready")
                    .foregroundStyle(.secondary)
            }
            .entranceAnimation(delay: 0.1)

            VStack(alignment: .leading, spacing: 24) {
                Text("What's next?")
                    .font(.headline)
                    .padding(.bottom, 4)

                featureRow(
                    icon: "calendar.badge.plus",
                    title: "Event Detection Active",
                    description: "We'll start scanning your messages for events"
                )

                featureRow(
                    icon: "bell.badge",
                    title: "Notifications Enabled",
                    description: "You'll be notified when we find new events"
                )

                featureRow(
                    icon: "arrow.triangle.2.circlepath",
                    title: "Automatic Sync",
                    description: "Events will be synced in real-time"
                )
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.green.opacity(0.1))
            )
            .entranceAnimation(delay: 0.2)

            OButton(label: "Done") {
                dismiss()
            }
            .entranceAnimation(delay: 0.3)
        }
    }

    private func failedSection(error: Error) -> some View {
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
                isLoading: viewModel.isLoading
            ) {
                viewModel.reset()
            }
            .entranceAnimation(delay: 0.3)
        }
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
        case .initializing:
            return "Complete Setup"
        }
    }

    // Add this custom button style for better press feedback
    struct PressableButtonStyle: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .scaleEffect(configuration.isPressed ? 0.95 : 1)
                .animation(.spring(response: 0.2, dampingFraction: 0.7), value: configuration.isPressed)
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
