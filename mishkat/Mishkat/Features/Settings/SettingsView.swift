//
//  SettingsView.swift
//  Mishkat
//
//  Created by Human on 20/10/2024.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
        
        var body: some View {
            Button("Logout") {
                authViewModel.logout()
            }
            // Add other settings options here
        }
}

#Preview {
    SettingsView()
}
