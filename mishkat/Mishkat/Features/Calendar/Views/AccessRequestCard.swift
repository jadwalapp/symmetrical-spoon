//
//  AccessRequestCard.swift
//  Mishkat
//
//  Created by Human on 20/10/2024.
//

import SwiftUI
import EventKit

struct AccessRequestCard: View {
    let status: EKAuthorizationStatus
    let requestAccess: () -> Void
    let openSettings: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 60))
                .foregroundColor(.accentColor)
            
            Text("Calendar Access Required")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("To use the calendar features, we need access to your calendar. This allows us to display and manage your events.")
                .multilineTextAlignment(.center)
                .font(.body)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            Button(action: {
                if status == .notDetermined {
                    requestAccess()
                } else {
                    openSettings()
                }
            }) {
                Text(status == .denied ? "Open Settings" : "Grant Access")
                    .fontWeight(.semibold)
                    .frame(minWidth: 200)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .frame(maxWidth: 300)
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.2), radius: 15, x: 0, y: 5)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
}

#Preview {
    AccessRequestCard(status: .notDetermined, requestAccess: {}, openSettings: {})
}
