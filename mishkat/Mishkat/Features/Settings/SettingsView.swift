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
                AsyncView(
                    response: profileViewModel.calDavAccountState
                ) { calDavAccount in
                    VStack(spacing: 16) {
                        HStack {
                            Image(systemName: "calendar")
                                .foregroundColor(.accentColor)
                                .font(.title2)
                            Text("CalDAV Credentials")
                                .font(.headline)
                        }
                        
                        VStack(spacing: 12) {
                            credentialRow(
                                title: "Username",
                                value: calDavAccount.username,
                                icon: "person.fill"
                            )
                            
                            credentialRow(
                                title: "Password",
                                value: calDavAccount.password,
                                icon: "lock.fill",
                                isSecure: true
                            )
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.gray.opacity(0.1))
                        )
                        
                        Button(action: {
                            UIPasteboard.general.string = """
                            Username: \(calDavAccount.username)
                            Password: \(calDavAccount.password)
                            """
                        }) {
                            Label("Copy Credentials", systemImage: "doc.on.doc")
                        }
                        .buttonStyle(.bordered)
                        .tint(.accentColor)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.accentColor.opacity(0.05))
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
            profileViewModel.getCalDavAccount()
        }
        .refreshable {
            profileViewModel.getProfile()
            profileViewModel.getCalDavAccount()
        }
    }
    
    func credentialRow(title: String, value: String, icon: String, isSecure: Bool = false) -> some View {
        HStack {
            Label(title, systemImage: icon)
                .foregroundColor(.secondary)
            Spacer()
            if isSecure {
                SecureField("", text: .constant(value))
                    .disabled(true)
                    .textFieldStyle(PlainTextFieldStyle())
                    .frame(width: 120)
            } else {
                Text(value)
                    .foregroundColor(.primary)
                    .font(.subheadline)
            }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(
            ProfileViewModel(
                profileRepository: DependencyContainer.shared.profileRepository,
                calendarRepository: DependencyContainer.shared.calendarRepository
            )
        )
}
