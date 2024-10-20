//
//  TokenSentView.swift
//  Mishkat
//
//  Created by Human on 20/10/2024.
//

import SwiftUI

struct TokenSentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        VStack(spacing: 20) {
            Text("Check your email")
                .font(.title)
            
            Text("We've sent a verification link to your email. Please check your inbox and click the link to continue.")
                .multilineTextAlignment(.center)
            
            OButton(icon: .mail, label: "Resend Email") {
                authViewModel.resendVerificationEmail()
            }
        }
        .padding()
    }
}

#Preview {
    TokenSentView()
}
