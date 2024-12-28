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
    @Published var navigationPath: [AuthNavigationDestination] = []
    
    @Published var email: String = ""
    
    @Published private(set) var initiateEmailState: AsyncValue<Auth_V1_InitiateEmailResponse> = .idle
    @Published private(set) var completeEmailState: AsyncValue<Auth_V1_CompleteEmailResponse> = .idle
    @Published private(set) var useGoogleState: AsyncValue<Auth_V1_UseGoogleResponse> = .idle
    
    
    private let authRepository: AuthRepository
    init(authRepository: AuthRepository) {
        self.authRepository = authRepository
        self.isAuthenticated = KeychainManager.shared.getToken() != nil
    }
    
    func useGoogle() {
        Task {
            await MainActor.run {
                useGoogleState = .loading
            }
            
            do {
                // TODO: Implement Google Sign-In
                let response = try await authRepository.useGoogle(googleToken: "googleToken")
                await MainActor.run {
                    KeychainManager.shared.saveToken(response.accessToken)
                    self.isAuthenticated = true
                    useGoogleState = .loaded(response)
                }
            } catch {
                await MainActor.run {
                    useGoogleState = .failed(error)
                }
            }
        }
    }
    
    func continueWithEmail() {
        navigationPath.append(.emailInput)
    }
    
    func initiateEmail(email: String) {
        Task {
            await MainActor.run {
                self.email = email
                self.initiateEmailState = .loading
            }
            
            do {
                let response = try await authRepository.initiateEmail(email: email)
                await MainActor.run {
                    self.initiateEmailState = .loaded(response)
                    self.navigationPath.append(.tokenSent)
                }
            } catch {
                await MainActor.run {
                    self.initiateEmailState = .failed(error)
                }
            }
        }
    }
    
    func resendVerificationEmail() {
        initiateEmail(email: email)
    }
    
    func completeEmail(token: String) {
        Task {
            await MainActor.run {
                self.completeEmailState = .loading
            }
            
            do {
                let response = try await authRepository.completeEmail(token: token)
                await MainActor.run {
                    KeychainManager.shared.saveToken(response.accessToken)
                    self.isAuthenticated = true
                    self.completeEmailState = .loaded(response)
                }
            } catch {
                await MainActor.run {
                    self.completeEmailState = .failed(error)
                }
            }
        }
    }
    
    func logout() {
        KeychainManager.shared.deleteToken()
        isAuthenticated = false
        navigationPath.removeAll()
        authState = .onboarding
        self.initiateEmailState = .idle
        self.completeEmailState = .idle
        self.useGoogleState = .idle
    }
}
