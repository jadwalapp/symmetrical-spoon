//
//  AuthView.swift
//  Mishkat
//
//  Created by Human on 20/10/2024.
//

import SwiftUI

struct AuthView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        NavigationStack(path: $authViewModel.navigationPath) {
            OnboardingView()
                .navigationDestination(for: AuthViewModel.AuthNavigationDestination.self) { destination in
                    switch destination {
                    case .emailInput:
                        EmailInputView()
                    case .tokenSent:
                        TokenSentView()
                    }
                }
        }
    }
}

struct AuthError: Identifiable {
    let id = UUID()
    let message: String
}

#Preview {
    AuthView()
}
