//
//  EmailInputView.swift
//  Mishkat
//
//  Created by Human on 20/10/2024.
//

import SwiftUI
import PostHog

struct EmailInputView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.colorScheme) var colorScheme
    @State private var email: String = ""
    @FocusState private var emailFieldFocused: Bool?
    
    var body: some View {
        ZStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 16) {
                        IconWithBackground(icon: .mail)
                            .pulsingAnimation()
                        
                        VStack(alignment: .leading) {
                            Text("Continue with Email")
                                .font(.title2)
                                .bold()
                                .entranceAnimation(delay: 0.1)
                            
                            Text("Sign in or sign up with your email")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .entranceAnimation(delay: 0.2)
                        }
                    }
                    
                    VStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 12) {
                                Image(systemName: "envelope.fill")
                                    .foregroundColor(.secondary)
                                
                                TextField("Email", text: $email)
                                    .font(.headline)
                                    .textFieldStyle(.plain)
                                    .autocapitalization(.none)
                                    .keyboardType(.emailAddress)
                                    .disabled(authViewModel.initiateEmailState == .loading)
                                    .focused($emailFieldFocused, equals: true)
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(colorScheme == .dark ? Color.gray.opacity(0.1) : Color.gray.opacity(0.05))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(emailFieldFocused == true ? Color.accentColor : Color.clear, lineWidth: 2)
                            )
                            
                            if !email.isEmpty {
                                HStack(spacing: 4) {
                                    Image(systemName: isValidEmail ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                                        .foregroundColor(isValidEmail ? .green : .orange)
                                    
                                    Text(isValidEmail ? "Valid email format" : "Please enter a valid email")
                                        .font(.caption)
                                        .foregroundColor(isValidEmail ? .green : .orange)
                                }
                                .transition(.opacity)
                            }
                        }
                        .entranceAnimation(delay: 0.3)
                        
                        VStack(spacing: 16) {
                            HStack(spacing: 12) {
                                Image(systemName: "lock.shield.fill")
                                    .font(.title2)
                                    .foregroundColor(.accentColor)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Secure Sign In or Sign Up")
                                        .font(.headline)
                                    Text("We'll send you a secure verification link")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            
                            Divider()
                            
                            VStack(alignment: .leading, spacing: 12) {
                                benefitRow(icon: "checkmark.shield.fill", text: "No password needed")
                                benefitRow(icon: "bolt.shield.fill", text: "Extra secure authentication")
                                benefitRow(icon: "clock.fill", text: "Quick and easy access")
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(colorScheme == .dark ? Color.accentColor.opacity(0.1) : Color.accentColor.opacity(0.05))
                        )
                        .entranceAnimation(delay: 0.4)
                    }
                    
                    if case .failed(let error) = authViewModel.initiateEmailState {
                        Snackbar(message: SnackbarMessage(
                            message: error.localizedDescription,
                            type: .error
                        ))
                        .entranceAnimation()
                    }
                    
                    Spacer()
                        .frame(height: 80)
                }
                .padding(24)
            }
            
            VStack {
                Spacer()
                VStack(spacing: 0) {
                    Divider()
                    
                    OButton(
                        icon: .arrowRight,
                        label: "Continue",
                        isLoading: authViewModel.initiateEmailState == .loading,
                        isDisabled: !isValidEmail || email.isEmpty
                    ) {
                        PostHogSDK.shared.capture("continue_with_email_continue_clicked")
                        authViewModel.initiateEmail(email: email)
                    }
                    .entranceAnimation(delay: 0.5)
                    .padding(24)
                    .background(colorScheme == .dark ? Color.black : Color.white)
                }
            }
        }
        .onAppear {
            emailFieldFocused = true
            PostHogSDK.shared.capture("continue_with_email_view_entered")
        }
    }
    
    // MARK: - Helper Views
    private func benefitRow(icon: String, text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(.accentColor)
            Text(text)
                .font(.subheadline)
        }
    }
    
    // MARK: - Computed Properties
    private var isValidEmail: Bool {
        let emailRegex = #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
}

#Preview {
    NavigationStack {
        EmailInputView()
            .environmentObject(AuthViewModel(
                authRepository: DependencyContainer.shared.authRepository,
                profileRepository: DependencyContainer.shared.profileRepository
            ))
    }
}
