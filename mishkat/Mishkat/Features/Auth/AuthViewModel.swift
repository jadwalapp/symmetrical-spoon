//
//  AuthViewModel.swift
//  Mishkat
//
//  Created by Human on 20/10/2024.
//

import SwiftUI

@MainActor
class AuthViewModel: ObservableObject {
    enum AuthState {
        case onboarding
        case emailInput
        case tokenSent
    }
    
    @Published var authState: AuthState = .onboarding
    @Published var isAuthenticated = false
    @Published var email: String = ""
    @Published var error: String?
    
    private let authRepository: AuthRepository
    
    init(authRepository: AuthRepository) {
        self.authRepository = authRepository
    }
    
    func continueWithGoogle() {
        Task {
            do {
                // TODO: get the google token somehow :D
                let response = try await authRepository.useGoogle(googleToken: "googleToken")
                self.isAuthenticated = true
            } catch {
                self.error = error.localizedDescription
            }
        }
    }
    
    func continueWithEmail() {
        authState = .emailInput
    }
    
    func submitEmail(email: String) {
        self.email = email
        Task {
            do {
                let _ = try await authRepository.initiateEmail(email: email)
                self.authState = .tokenSent
            } catch {
                self.error = error.localizedDescription
            }
        }
    }
    
    func resendVerificationEmail() {
        submitEmail(email: email)
    }
    
    func completeEmailVerification(token: String) {
        Task {
            do {
                let _ = try await authRepository.completeEmail(token: token)
                self.isAuthenticated = true
            } catch {
                self.error = error.localizedDescription
            }
        }
    }
}
