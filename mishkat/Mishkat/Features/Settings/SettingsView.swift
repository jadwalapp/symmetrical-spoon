//
//  SettingsView.swift
//  Mishkat
//
//  Created by Human on 20/10/2024.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var settingsViewModel: SettingsViewModel
    
    var body: some View {
        List {
            Section {
                SettingsProfileTile(
                    name: settingsViewModel.profileData?.name ?? "",
                    email: settingsViewModel.profileData?.email ?? ""
                )
            }
            Section {
                Button {
                    print("connect whatsapp")
                } label: {
                    HStack {
                        Image(systemName: "message.fill")
                        Text("Connect WhatsApp")
                    }
                }
                
                Button {
                    print("connect caldav")
                } label: {
                    HStack {
                        Image(systemName: "calendar")
                        Text("Connect CalDAV")
                    }
                }
            }
            Section {
                HStack {
                    Spacer()
                    Button {
                        authViewModel.logout()
                    } label: {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                            Text("Logout")
                        }
                        .foregroundStyle(.red)
                    }
                    Spacer()
                }
            }
        }
        .task {
            settingsViewModel.getProfile()
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(
            SettingsViewModel(
                profileRepository: DependencyContainer.shared.profileRepository
            )
        )
}
