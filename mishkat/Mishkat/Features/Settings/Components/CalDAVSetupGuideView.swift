//
//  CalDAVSetupGuideView.swift
//  Mishkat
//
//  Created by Human on 16/01/2025.
//

import SwiftUI

struct CalDAVSetupGuideView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("CalDAV Setup Guide")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                ForEach(1...6, id: \.self) { step in
                    guideStep(number: step)
                }
            }
            .padding()
        }
    }
    
    private func guideStep(number: Int) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Step \(number)")
                .font(.headline)
            Text(stepDescription(for: number))
                .font(.body)
                .foregroundColor(.secondary)
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

#Preview {
    CalDAVSetupGuideView()
}
