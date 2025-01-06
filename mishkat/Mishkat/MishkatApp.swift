//
//  MishkatApp.swift
//  Mishkat
//
//  Created by Human on 19/10/2024.
//

import SwiftUI

@main
struct MishkatApp: App {
    @StateObject private var authViewModel: AuthViewModel
    
    init() {
        _authViewModel = StateObject(wrappedValue: AuthViewModel(authRepository: DependencyContainer.shared.authRepository))
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authViewModel)
                .onOpenURL { url in
                    handleDeepLink(url)
                }
        }
    }
    
    private func handleDeepLink(_ url: URL) {
        guard url.path == "/magic-link",
              let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
              let token = components.queryItems?.first(where: { $0.name == "token" })?.value
        else {
            return
        }
        
        authViewModel.completeEmail(token: token)
    }
}
