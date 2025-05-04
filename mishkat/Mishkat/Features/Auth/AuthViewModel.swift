//
//  AuthViewModel.swift
//  Mishkat
//
//  Created by Human on 20/10/2024.
//

import SwiftUI
import UIKi
import PostHog

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
    private let profileRepository: ProfileRepository
    
    init(authRepository: AuthRepository, profileRepository: ProfileRepository) {
        self.authRepository = authRepository
        self.profileRepository = profileRepository
        self.isAuthenticated = KeychainManager.shared.getToken() != nil
    }
    
    private func registerDeviceToken() {
        Task {
            guard let appDelegate = await UIApplication.shared.delegate as? MishkatAppDelegate,
                  let deviceToken = await appDelegate.currentDeviceToken else {
                print("Device token not available yet for registration.")
                await UIApplication.shared.registerForRemoteNotifications()
                return
            }

            print("Attempting to register device token after login: \(deviceToken)")
            do {
                try await self.profileRepository.addDevice(deviceToken: deviceToken)
                print("Device token registered successfully after login.")
            } catch {
                print("Failed to register device token after login: \(error)")
            }
        }
    }
    
    func useGoogle() {
        Task {
            await MainActor.run {
                useGoogleState = .loading
            }
            
            do {
                // TODO: Implement Google Sign-In
                let response = try await authRepository.useGoogle(googleToken: "googleToken")
                PostHogSDK.shared.identify(response.userID)
                await MainActor.run {
                    KeychainManager.shared.saveToken(response.accessToken)
                    self.isAuthenticated = true
                    useGoogleState = .loaded(response)
                    self.registerDeviceToken()
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

                // hard coded for apple tester, backend knows about it :D
                if email == "apple-tester@jadwal.app" {
                    self.completeEmail(token: "77d55f11-320d-4cef-b46c-9476fef1db0d")
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
                PostHogSDK.shared.identify(response.userID)
                await MainActor.run {
                    KeychainManager.shared.saveToken(response.accessToken)
                    self.isAuthenticated = true
                    self.completeEmailState = .loaded(response)
                    self.registerDeviceToken()
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
