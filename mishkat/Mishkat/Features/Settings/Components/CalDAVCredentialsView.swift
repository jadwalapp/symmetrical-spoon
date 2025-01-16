//
//  CalDAVCredentialsView.swift
//  Mishkat
//
//  Created by Human on 16/01/2025.
//

import SwiftUI

struct CalDAVCredentialsView: View {
    @EnvironmentObject var profileViewModel: ProfileViewModel
    @State private var isExpanded = false
    @State private var showingSetupGuide = false
    @State private var copiedField: String?

    var body: some View {
        VStack(spacing: 0) {
            header
            
            VStack {
                if isExpanded {
                    credentialsContent
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .clipped()
        }
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        .animation(.easeInOut(duration: 0.25), value: isExpanded)
        .sheet(isPresented: $showingSetupGuide) {
            CalDAVSetupGuideView()
        }
    }

    private var header: some View {
        Button(action: { withAnimation { isExpanded.toggle() } }) {
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(.accentColor)
                    .font(.title2)
                Text("CalDAV Account")
                    .font(.headline)
                Spacer()
                Image(systemName: isExpanded ? "chevron.up.circle.fill" : "chevron.down.circle.fill")
                    .foregroundColor(.accentColor)
                    .imageScale(.large)
            }
            .padding()
            .background(Color(UIColor.secondarySystemBackground))
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var credentialsContent: some View {
        VStack(spacing: 20) {
            AsyncView(response: profileViewModel.calDavAccountState) { account in
                VStack(spacing: 16) {
                    credentialRow(title: "Server URL", value: "https://baikal.jadwal.app/dav.php", systemImage: "globe")
                    credentialRow(title: "Username", value: account.username, systemImage: "person.fill")
                    credentialRow(title: "Password", value: account.password, systemImage: "lock.fill", isSecure: true)
                }
            }
            
            HStack(spacing: 20) {
                actionButton(title: "Setup Guide", systemImage: "book.fill") {
                    showingSetupGuide = true
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
    }

    private func credentialRow(title: String, value: String, systemImage: String, isSecure: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: systemImage)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack {
                Group {
                    if isSecure {
                        SecureField("", text: .constant(value))
                            .disabled(true)
                    } else {
                        Text(value)
                    }
                }
                .font(.body.monospaced())
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(Color(UIColor.tertiarySystemBackground))
                .cornerRadius(8)
                
                Button(action: {
                    UIPasteboard.general.string = value
                    copiedField = title
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        if copiedField == title {
                            copiedField = nil
                        }
                    }
                }) {
                    Image(systemName: copiedField == title ? "checkmark.circle.fill" : "doc.on.doc")
                        .foregroundColor(copiedField == title ? .green : .accentColor)
                        .frame(width: 44, height: 44)
                        .background(Color(UIColor.tertiarySystemBackground))
                        .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }

    private func actionButton(title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
        }
        .buttonStyle(.bordered)
        .tint(.accentColor)
    }
}

#Preview {
    CalDAVCredentialsView()
}
