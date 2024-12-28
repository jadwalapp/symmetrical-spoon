//
//  EmailInputView.swift
//  Mishkat
//
//  Created by Human on 20/10/2024.
//

import SwiftUI

struct EmailInputView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var email: String = ""
    
    @FocusState private var emailFieldFocused: Bool?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 16) {
                IconWithBackground(icon: .mail)
                VStack(alignment: .leading) {
                    Text("Continue with Email")
                        .font(.title2)
                        .bold()
                    Text("Sign in or sign up with your email")
                        .font(.subheadline)
                        .foregroundStyle(.subheadline)
                }
            }
            
            TextField("Email", text: $email)
                .padding()
                .background(.lightGray)
                .font(.headline)
                .cornerRadius(16)
                .textFieldStyle(.plain)
                .autocapitalization(.none)
                .keyboardType(.emailAddress)
                .disabled(authViewModel.initiateEmailState == .loading)
                .focused($emailFieldFocused, equals: true)
                .onAppear {
                    emailFieldFocused = true
                }
            
            if case .failed(let error) = authViewModel.initiateEmailState {
                Text("\(error.localizedDescription)")
                    .font(.callout)
                    .foregroundStyle(.red)
                    .bold()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
            
            OButton(
                icon: .mail,
                label: "Continue",
                isLoading: authViewModel.initiateEmailState == .loading,
                isDisabled: email.isEmpty
            ) {
                authViewModel.initiateEmail(
                    email: email
                )
            }
            
        }
        .padding(24)
    }
}

#Preview {
    NavigationStack {
        EmailInputView()
            .environmentObject(AuthViewModel(
                authRepository: DependencyContainer.shared.authRepository
            ))
    }
}
