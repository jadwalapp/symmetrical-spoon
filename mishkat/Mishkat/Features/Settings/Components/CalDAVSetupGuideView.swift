//
//  CalDAVSetupGuideView.swift
//  Mishkat
//
//  Created by Human on 16/01/2025.
//

import SwiftUI

struct CalDAVSetupGuideView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    HeaderView()
                    NoteView()
                    CredentialsView()
                    
                    // Steps
                    ForEach(1...6, id: \.self) { step in
                        GuideStepView(number: step, description: stepDescription(for: step))
                    }
                }
                .padding()
            }
            .navigationTitle("Manual Setup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func stepDescription(for step: Int) -> String {
        switch step {
        case 1: return "Copy your CalDAV credentials from the previous screen."
        case 2: return "Open your preferred calendar application on your device."
        case 3: return "Navigate to the account settings or 'Add Account' section."
        case 4: return "Choose 'CalDAV' or 'Other' as the account type."
        case 5: return "Enter the server address, your username, and password."
        case 6: return "Save the settings and wait for the initial sync to complete."
        default: return ""
        }
    }
}

// MARK: - Component Views

struct HeaderView: View {
    var body: some View {
        Text("Manual CalDAV Setup")
            .font(.largeTitle)
            .fontWeight(.bold)
    }
}

struct NoteView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 0) {
                Text("Note:")
                    .fontWeight(.bold)
                
                Text(" The ")
                    .foregroundStyle(.secondary)
                
                Text("Easy Setup")
                    .foregroundStyle(Color.accentColor)
                    .fontWeight(.semibold)
                
                Text(" option is recommended.")
                    .foregroundStyle(.secondary)
            }
            
            Text("This manual guide is provided as a fallback option.")
                .foregroundStyle(.secondary)
        }
        .font(.callout)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct CredentialsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Server Information")
                .font(.headline)
                .padding(.bottom, 4)
            
            HStack {
                Text("Server URL:")
                    .fontWeight(.medium)
                Text("https://baikal.jadwal.app/dav.php")
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(Color.accentColor)
            }
            
            Text("Use the account credentials shown in the Calendar Sync section")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct GuideStepView: View {
    let number: Int
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                StepNumberView(number: number)
                
                Text("Step \(number)")
                    .font(.headline)
            }
            
            Text(description)
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct StepNumberView: View {
    let number: Int
    
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.accentColor)
                .frame(width: 24, height: 24)
            
            Text("\(number)")
                .foregroundStyle(.white)
                .font(.footnote.bold())
        }
    }
}

#Preview {
    CalDAVSetupGuideView()
}
