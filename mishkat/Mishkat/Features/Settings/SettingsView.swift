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
                CalDAVCredentialsView()
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
            }
            Section {
                AsyncView(
                    response: profileViewModel.whatsappAccountState
                ) { whatsappAccount in
                    if whatsappAccount.isReady {
                        HStack {
                            Image(systemName: "message.fill")
                            VStack(alignment: .leading) {
                                Text("WhatsApp Connected")
                                Text(whatsappAccount.phoneNumber)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Button {
                                profileViewModel.disconnectWhatsapp()
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.red)
                            }
                        }
                    } else {
                        Button {
                            profileViewModel.showWhatsappSheet = true
                        } label: {
                            HStack {
                                Image(systemName: "message.fill")
                                Text("Connect WhatsApp")
                            }
                        }
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
            profileViewModel.getCalDavAccount()
            profileViewModel.getWhatsappAccount()
        }
        .refreshable {
            profileViewModel.getProfile()
            profileViewModel.getCalDavAccount()
            profileViewModel.getWhatsappAccount()
        }
        .sheet(isPresented: $profileViewModel.showWhatsappSheet) {
            WhatsappConnectionSheet(whatsappRepository: DependencyContainer.shared.whatsappRepository)
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(
            ProfileViewModel(
                profileRepository: DependencyContainer.shared.profileRepository,
                calendarRepository: DependencyContainer.shared.calendarRepository, whatsappRepository: DependencyContainer.shared.whatsappRepository
            )
        )
}
