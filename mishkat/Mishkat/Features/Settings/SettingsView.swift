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
                        VStack(spacing: 16) {
                            HStack {
                                Image(systemName: "message.fill")
                                    .foregroundStyle(.green)
                                    .font(.title3)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("WhatsApp Connected")
                                        .font(.headline)
                                    Text(whatsappAccount.phoneNumber)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Menu {
                                    Button(role: .destructive) {
                                        profileViewModel.disconnectWhatsapp()
                                    } label: {
                                        Label("Disconnect", systemImage: "xmark.circle")
                                    }
                                } label: {
                                    Image(systemName: "ellipsis.circle")
                                        .foregroundStyle(.secondary)
                                        .font(.title3)
                                }
                            }
                            
                            if !whatsappAccount.name.isEmpty {
                                HStack {
                                    Image(systemName: "person.fill")
                                        .foregroundStyle(.secondary)
                                    Text(whatsappAccount.name)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                }
                            }
                            
                            HStack {
                                Image(systemName: "checkmark.seal.fill")
                                    .foregroundStyle(.green)
                                Text("Scanning messages for events")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                Spacer()
                            }
                        }
                        .padding(.vertical, 4)
                    } else if whatsappAccount.status == "WAITING_FOR_PAIRING" {
                        Button {
                            profileViewModel.showWhatsappSheet = true
                        } label: {
                            HStack {
                                Image(systemName: "message.badge.circle.fill")
                                    .font(.title3)
                                    .foregroundStyle(.orange)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Complete WhatsApp Setup")
                                        .font(.headline)
                                    Text("Waiting for pairing code")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                    } else {
                        Button {
                            profileViewModel.showWhatsappSheet = true
                        } label: {
                            HStack {
                                Image(systemName: "message.fill")
                                    .font(.title3)
                                    .foregroundStyle(.green)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Connect WhatsApp")
                                        .font(.headline)
                                    Text("Sync your events from chats")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
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
            Task {
                await profileViewModel.checkDeviceCalDavAccountStatus()
            }
        }
        .onAppear {
            Task {
                await profileViewModel.checkDeviceCalDavAccountStatus()
            }
        }
        .refreshable {
            profileViewModel.getProfile()
            profileViewModel.getCalDavAccount()
            profileViewModel.getWhatsappAccount()
            await profileViewModel.checkDeviceCalDavAccountStatus()
        }
        .sheet(isPresented: $profileViewModel.showWhatsappSheet) {
            WhatsappConnectionSheet(whatsappRepository: DependencyContainer.shared.whatsappRepository)
                .presentationDragIndicator(.visible)
                .presentationDetents([.large])
                .onDisappear {
                    profileViewModel.getWhatsappAccount()
                }
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
