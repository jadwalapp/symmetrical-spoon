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

    var body: some View {
        VStack(spacing: 20) {
            Text("Enter your email")
                .font(.title)
            
            TextField("Email", text: $email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.none)
                .keyboardType(.emailAddress)
            
            OButton(icon: .mail, label: "Continue") {
                authViewModel.submitEmail(email: email)
            }
        }
        .padding()
    }
}

#Preview {
    EmailInputView()
}
