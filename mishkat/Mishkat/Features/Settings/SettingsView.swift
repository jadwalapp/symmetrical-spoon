//
//  SettingsView.swift
//  Mishkat
//
//  Created by Human on 20/10/2024.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var profileViewModel: ProfileViewModel
    
    var body: some View {
        List {
            Section {
                AsyncView(
                    response: profileViewModel.profileState
                ) { profile in
                    SettingsProfileTile(
                        name: profile.name,
                        email: profile.email
                    )
                }
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
        .onFirstAppear {
            profileViewModel.getProfile()
        }
        .refreshable {
            profileViewModel.getProfile()
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(
            ProfileViewModel(
                profileRepository: DependencyContainer.shared.profileRepository
            )
        )
}
