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
            List {
                Section {
                    HStack {
                        Circle()
                            .frame(width: 60)
                            .padding(.trailing, 16)
                        VStack(alignment: .leading) {
                            Text("Hello Yazeed!")
                                .font(.headline)
                            Text("yazeedfady@gmail.com")
                                .font(.subheadline)
                        }
                        Spacer()
                    }
                }
                Section {
                    
                }
                Section {
                    HStack {
                        Spacer()
                        Button("Logout") {
                            authViewModel.logout()
                        }
                        .foregroundStyle(.red)
                        Spacer()
                    }
                }
            }
        }
}

#Preview {
    SettingsView()
}
