//
//  CalDAVCredentialsView.swift
//  Mishkat
//
//  Created by Human on 16/01/2025.
//

import SwiftUI

struct CalDAVCredentialsView: View {
    @EnvironmentObject var profileViewModel: ProfileViewModel
    @State private var copiedField: String?
    @State private var showingEasySetupInstructions = false
    @State private var isAccountDetailsExpanded = false
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.secondarySystemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
            
            VStack(spacing: 0) {
                // Header
                header
                
                Divider()
                
                // Content
                VStack(spacing: 16) {
                    connectionStatusView
                    
                    if profileViewModel.isDeviceCalDavAccountDetected {
                        accountDetailsView
                    } else {
                        setupOptionsView
                    }
                }
                .padding()
            }
        }
        // Only keep the Easy Setup sheet
        .fullScreenCover(isPresented: $showingEasySetupInstructions) {
            CalDAVSetupInstructionsView()
                .environmentObject(profileViewModel)
        }
    }
    
    // MARK: - UI Components
    
    private var header: some View {
        HStack {
            Image(systemName: "calendar")
                .foregroundStyle(Color.accentColor)
                .font(.title2)
            
            Text("Calendar Sync")
                .font(.headline)
            
            Spacer()
            
            Button {
                Task {
                    await profileViewModel.checkDeviceCalDavAccountStatus()
                }
            } label: {
                Image(systemName: "arrow.clockwise")
                    .foregroundStyle(Color.accentColor)
            }
            .buttonStyle(.plain)
        }
        .padding()
    }
    
    private var connectionStatusView: some View {
        HStack(spacing: 12) {
            // Status icon with loading state
            ZStack {
                if case .loading = profileViewModel.calDavAccountState {
                    ProgressView()
                        .frame(width: 40, height: 40)
                } else {
                    Circle()
                        .fill(profileViewModel.isDeviceCalDavAccountDetected ? Color.green : Color.gray.opacity(0.3))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: profileViewModel.isDeviceCalDavAccountDetected ? "checkmark" : "xmark")
                        .foregroundStyle(.white)
                        .font(.system(size: 16, weight: .bold))
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                if case .loading = profileViewModel.calDavAccountState {
                    Text("Checking Connection...")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                } else {
                    Text(profileViewModel.isDeviceCalDavAccountDetected ? "Connected" : "Not Connected")
                        .font(.headline)
                        .foregroundStyle(profileViewModel.isDeviceCalDavAccountDetected ? .green : .secondary)
                }
                
                Text(profileViewModel.isDeviceCalDavAccountDetected ? 
                    "Your CalDAV calendars are syncing with this device" : 
                    "Set up CalDAV to sync your calendars")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(profileViewModel.isDeviceCalDavAccountDetected ? Color.green.opacity(0.1) : Color(.systemGray6))
        )
    }
    
    private var accountDetailsView: some View {
        VStack(spacing: 16) {
            // Title row with expand/collapse button
            HStack {
                Text("Account Details")
                    .font(.headline)
                
                Spacer()
                
                Button {
                    withAnimation {
                        isAccountDetailsExpanded.toggle()
                    }
                } label: {
                    Image(systemName: isAccountDetailsExpanded ? "chevron.up" : "chevron.down")
                        .foregroundStyle(Color.accentColor)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 4)
            
            if isAccountDetailsExpanded {
                AsyncView(response: profileViewModel.calDavAccountState) { account in
                    VStack(spacing: 16) {
                        // Credential cards
                        credentialCard(
                            title: "Server",
                            value: "https://baikal.jadwal.app/dav.php",
                            icon: "server.rack"
                        )
                        
                        credentialCard(
                            title: "Username",
                            value: account.username,
                            icon: "person.fill"
                        )
                        
                        credentialCard(
                            title: "Password",
                            value: account.password,
                            icon: "lock.fill",
                            isSecure: true
                        )
                    }
                }
            } else {
                HStack {
                    Text("Tap to view your CalDAV credentials")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .padding(.horizontal, 4)
            }
        }
    }
    
    private var setupOptionsView: some View {
        VStack(spacing: 20) {
            // Easy setup button (primary)
            Button {
                showingEasySetupInstructions = true
            } label: {
                Label("Easy Setup", systemImage: "wand.and.stars")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            
            // Description
            Text("Automatically configure your device for CalDAV sync")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            /* Commenting out Manual Setup for now
            Divider()
            
            // Manual setup button (secondary)
            Button {
                showingEasySetupInstructions = false  // Ensure the other sheet is off
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    showingManualSetupGuide = true
                }
            } label: {
                Label("Manual Setup", systemImage: "gear")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .foregroundStyle(.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            */
        }
    }
    
    private func credentialCard(title: String, value: String, icon: String, isSecure: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // Title row
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(Color.accentColor)
                
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Spacer()
            }
            
            // Value row with copy button
            HStack {
                Group {
                    if isSecure {
                        SecureField("", text: .constant(value))
                            .disabled(true)
                    } else {
                        Text(value)
                            .lineLimit(1)
                    }
                }
                .font(.subheadline.monospaced())
                .textSelection(.enabled)
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                
                Spacer()
                
                Button {
                    UIPasteboard.general.string = value
                    copiedField = title
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        if copiedField == title {
                            copiedField = nil
                        }
                    }
                } label: {
                    Image(systemName: copiedField == title ? "checkmark.circle.fill" : "doc.on.doc")
                        .foregroundStyle(copiedField == title ? .green : Color.accentColor)
                        .padding(8)
                }
                .buttonStyle(.plain)
            }
            .background(Color(UIColor.tertiarySystemBackground))
            .cornerRadius(8)
        }
        .padding(.horizontal, 4)
    }
}

#Preview {
    VStack {
        CalDAVCredentialsView()
            .padding()
    }
    .background(Color(UIColor.systemBackground))
    .environmentObject(ProfileViewModel(
        profileRepository: DependencyContainer.shared.profileRepository,
        calendarRepository: DependencyContainer.shared.calendarRepository,
        whatsappRepository: DependencyContainer.shared.whatsappRepository
    ))
}
