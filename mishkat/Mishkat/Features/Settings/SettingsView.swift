//
//  SettingsView.swift
//  Mishkat
//
//  Created by Human on 20/10/2024.
//

import SwiftUI
import SafariServices
import PostHog

struct SettingsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var profileViewModel: ProfileViewModel
    @EnvironmentObject var settingsViewModel: SettingsViewModel
    
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
                // Prayer Times Calendar Setup
                PrayerTimesSetupView()
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
                                        PostHogSDK.shared.capture("disconnect_whatsapp_clicked")
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
                            PostHogSDK.shared.capture("complete_whatsapp_clicked")
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
                            PostHogSDK.shared.capture("connect_whatsapp_clicked")
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
        .environmentObject(settingsViewModel)
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

// MARK: - Safari View Wrapper
struct SafariViewWrapper: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: Context) -> SFSafariViewController {
        let config = SFSafariViewController.Configuration()
        config.entersReaderIfAvailable = false
        let safariVC = SFSafariViewController(url: url, configuration: config)
        safariVC.preferredControlTintColor = UIColor(Color.accentColor)
        safariVC.preferredBarTintColor = .systemBackground
        return safariVC
    }
    
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
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
