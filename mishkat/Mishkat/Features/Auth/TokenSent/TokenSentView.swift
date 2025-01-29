//
//  TokenSentView.swift
//  Mishkat
//
//  Created by Human on 20/10/2024.
//

import SwiftUI

struct TokenSentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.colorScheme) var colorScheme
    @State private var showResendFeedback = false
    @State private var showMailAppPicker = false
    
    var body: some View {
        ZStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 20) {
                        IconWithBackground(icon: .mail)
                            .pulsingAnimation()
                            .overlay(
                                Group {
                                    if case .failed = authViewModel.completeEmailState {
                                        Image(systemName: "exclamationmark.circle.fill")
                                            .foregroundColor(.red)
                                            .offset(x: 20, y: -20)
                                    }
                                }
                            )
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text(getHeaderTitle())
                                .font(.title)
                                .bold()
                                .entranceAnimation(delay: 0.1)
                            
                            Text(getHeaderSubtitle())
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .entranceAnimation(delay: 0.2)
                        }
                    }
                    
                    VStack(spacing: 20) {
                        HStack(spacing: 16) {
                            Image(systemName: "envelope.badge.shield.half.filled")
                                .font(.title)
                                .foregroundColor(getStatusColor())
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Secure verification")
                                    .font(.headline)
                                Text(getStatusText())
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(getStatusBackgroundColor())
                        )
                        .entranceAnimation(delay: 0.3)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text(getTroubleshootingTitle())
                                .font(.subheadline)
                                .bold()
                            
                            ForEach(getTroubleshootingTips(), id: \.self) { tip in
                                HStack(spacing: 8) {
                                    Image(systemName: tip.icon)
                                        .foregroundColor(.secondary)
                                    Text(tip.text)
                                        .font(.subheadline)
                                }
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(.lightGray)
                        )
                        .entranceAnimation(delay: 0.4)
                    }
                    
                    if let error = getError() {
                        Snackbar(message: SnackbarMessage(
                            message: error.localizedDescription,
                            type: .error
                        ))
                    }
                    
                    Spacer()
                        .frame(height: 160)
                }
                .padding(24)
            }
            
            VStack {
                Spacer()
                VStack(spacing: 0) {
                    Divider()
                    
                    VStack(spacing: 16) {
                        if case .failed = authViewModel.completeEmailState {
                            OButton(
                                icon: .rotate,
                                label: "Try Again",
                                style: .primary,
                                isDisabled: isLoading
                            ) {
                                authViewModel.initiateEmail(email: authViewModel.email)
                            }
                            .entranceAnimation(delay: 0.5)
                        } else {
                            OButton(
                                icon: .mail,
                                label: "Open Mail App",
                                style: .primary,
                                isDisabled: isLoading
                            ) {
                                showMailAppPicker = true
                            }
                            .entranceAnimation(delay: 0.5)
                        }
                        
                        VStack(spacing: 8) {
                            OButton(
                                icon: .rotate,
                                label: "Resend Email",
                                style: .secondary,
                                isLoading: authViewModel.initiateEmailState == .loading,
                                isDisabled: isLoading
                            ) {
                                withAnimation {
                                    showResendFeedback = true
                                }
                                authViewModel.resendVerificationEmail()
                                
                                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                    withAnimation {
                                        showResendFeedback = false
                                    }
                                }
                            }
                            .entranceAnimation(delay: 0.6)
                            
                            if showResendFeedback {
                                Text("Email sent! Please check your inbox")
                                    .font(.caption)
                                    .foregroundColor(.green)
                                    .transition(.opacity)
                            }
                        }
                    }
                    .padding(24)
                    .background(colorScheme == .dark ? Color.black : Color.white)
                }
            }
            
            if case .loading = authViewModel.completeEmailState {
                LoadingOverlay(message: "Verifying your email...")
            }
        }
        .sheet(isPresented: $showMailAppPicker) {
            MailAppPickerSheet()
        }
    }
    
    private var isLoading: Bool {
        if case .loading = authViewModel.initiateEmailState { return true }
        if case .loading = authViewModel.completeEmailState { return true }
        return false
    }
    
    private func getError() -> Error? {
        switch authViewModel.completeEmailState {
        case .failed(let error):
            return error
        default:
            switch authViewModel.initiateEmailState {
            case .failed(let error):
                return error
            default:
                return nil
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func getHeaderTitle() -> String {
        switch authViewModel.completeEmailState {
        case .failed:
            return "Verification Failed"
        case .loaded:
            return "Email Verified!"
        default:
            return "Check your email"
        }
    }
    
    private func getHeaderSubtitle() -> String {
        switch authViewModel.completeEmailState {
        case .failed:
            return "We couldn't verify your email. Please try again."
        case .loaded:
            return "Your email has been successfully verified."
        default:
            return "We've sent a verification link to your email"
        }
    }
    
    private func getStatusColor() -> Color {
        switch authViewModel.completeEmailState {
        case .failed:
            return .red
        case .loaded:
            return .green
        default:
            return .accentColor
        }
    }
    
    private func getStatusBackgroundColor() -> Color {
        let baseColor: Color = {
            switch authViewModel.completeEmailState {
            case .failed:
                return .red
            case .loaded:
                return .green
            default:
                return .accentColor
            }
        }()
        return colorScheme == .dark ? baseColor.opacity(0.1) : baseColor.opacity(0.05)
    }
    
    private func getStatusText() -> String {
        switch authViewModel.completeEmailState {
        case .failed:
            return "Verification link expired or invalid"
        case .loaded:
            return "Email successfully verified"
        default:
            return "Link expires in 15 minutes"
        }
    }
    
    private func getTroubleshootingTitle() -> String {
        switch authViewModel.completeEmailState {
        case .failed:
            return "Common issues:"
        case .loaded:
            return "What's next?"
        default:
            return "Can't find the email?"
        }
    }
    
    private struct TroubleshootingTip: Hashable {
        let icon: String
        let text: String
    }
    
    private func getTroubleshootingTips() -> [TroubleshootingTip] {
        switch authViewModel.completeEmailState {
        case .failed:
            return [
                TroubleshootingTip(icon: "clock.badge.exclamationmark", text: "Link may have expired"),
                TroubleshootingTip(icon: "link.badge.plus", text: "Request a new verification link"),
                TroubleshootingTip(icon: "envelope.badge.shield", text: "Check if you used the correct email")
            ]
        case .loaded:
            return [
                TroubleshootingTip(icon: "checkmark.circle", text: "Your email is now verified"),
                TroubleshootingTip(icon: "person.crop.circle", text: "Complete your profile"),
                TroubleshootingTip(icon: "arrow.right.circle", text: "Continue to the app")
            ]
        default:
            return [
                TroubleshootingTip(icon: "folder", text: "Check your spam folder"),
                TroubleshootingTip(icon: "clock", text: "Allow up to 5 minutes for delivery")
            ]
        }
    }
}

#Preview {
    TokenSentView()
        .environmentObject(AuthViewModel(
            authRepository: DependencyContainer.shared.authRepository
        ))
}
