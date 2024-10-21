//
//  AuthViewModel.swift
//  Mishkat
//
//  Created by Human on 20/10/2024.
//

import SwiftUI

class AuthViewModel: ObservableObject {
    enum AuthState {
        case onboarding
        case emailInput
        case tokenSent
    }
    
    enum AuthNavigationDestination: Hashable {
        case emailInput
        case tokenSent
    }
    
    @Published var authState: AuthState = .onboarding
    @Published var isAuthenticated = false
    @Published var email: String = ""
    @Published var error: String?
    @Published var isLoading = false
    @Published var navigationPath: [AuthNavigationDestination] = []
    
    private let authRepository: AuthRepository
    
    init(authRepository: AuthRepository) {
        self.authRepository = authRepository
        self.isAuthenticated = KeychainManager.shared.getToken() != nil
    }
    
    func continueWithGoogle() {
        isLoading = true
        Task {
            do {
                // TODO: Implement Google Sign-In
                let response = try await authRepository.useGoogle(googleToken: "googleToken")
                await MainActor.run {
                    KeychainManager.shared.saveToken(response.accessToken)
                    self.isAuthenticated = true
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.error = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
    
    func continueWithEmail() {
        navigationPath.append(.emailInput)
    }
    
    func submitEmail(email: String) {
        self.email = email
        isLoading = true
        Task {
            do {
                let _ = try await authRepository.initiateEmail(email: email)
                await MainActor.run {
                    self.navigationPath.append(.tokenSent)
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.error = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
    
    func resendVerificationEmail() {
        submitEmail(email: email)
    }
    
    func handleMagicLink(token: String) {
        isLoading = true
        Task {
            do {
                let response = try await authRepository.completeEmail(token: token)
                await MainActor.run {
                    KeychainManager.shared.saveToken(response.accessToken)
                    self.isAuthenticated = true
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.error = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }

    func logout() {
        KeychainManager.shared.deleteToken()
        isAuthenticated = false
        navigationPath.removeAll()
        authState = .onboarding
    }
}
