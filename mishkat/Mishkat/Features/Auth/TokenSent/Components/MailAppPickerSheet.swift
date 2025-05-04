//
//  MailAppPickerSheet.swift
//  Mishkat
//
//  Created by Human on 28/12/2024.
//

import SwiftUI
import PostHog

struct MailAppPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme
    @State private var notInstalledApp: String?
    @State private var contentHeight: CGFloat = 0
    
    let mailApps: [(name: String, urlScheme: String, icon: String)] = [
        ("Apple Mail", "mailto:", "AppleMail"),
        ("Gmail", "googlegmail://", "Gmail"),
        ("Outlook", "ms-outlook://", "Outlook")
    ]
    
    var body: some View {
        GeometryReader { geometry in
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Choose Mail App")
                            .font(.title3)
                            .bold()
                        Text("Open your preferred email app")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                
                VStack(spacing: 12) {
                    ForEach(mailApps, id: \.urlScheme) { app in
                        Button {
                            openMailApp(app)
                        } label: {
                            HStack(spacing: 16) {
                                Image(app.icon)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 48)
                                    .scaleEffect(0.8)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(app.name)
                                        .font(.headline)
                                        .foregroundStyle(.primary)
                                    
                                    if notInstalledApp == app.name {
                                        Text("App not installed")
                                            .font(.caption)
                                            .foregroundColor(.red)
                                    }
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(24)
            .background(Color(UIColor.systemBackground))
            .background(
                GeometryReader { proxy in
                    Color.clear.onAppear {
                        contentHeight = proxy.size.height
                    }
                }
            )
        }
        .presentationDragIndicator(.visible)
        .presentationDetents([.height(contentHeight)])
        .onAppear {
            PostHogSDK.shared.capture("mail_app_picker_sheet_shown")
        }
    }
    
    private func openMailApp(_ app: (name: String, urlScheme: String, icon: String)) {
        PostHogSDK.shared.capture("open_mail_app_triggered", properties: [
            "app_name": app.name,
            "app_url_scheme": app.urlScheme,
            "icon_name": app.icon
        ])
        if app.urlScheme == "mailto:" {
            if let url = URL(string: "mailto:") {
                UIApplication.shared.open(url)
                dismiss()
            }
            return
        }
        
        if let url = URL(string: app.urlScheme) {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
                dismiss()
            } else {
                withAnimation {
                    notInstalledApp = app.name
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    if let mailtoURL = URL(string: "mailto:") {
                        UIApplication.shared.open(mailtoURL)
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    VStack {
        
    }.sheet(isPresented: .constant(true)) {
        MailAppPickerSheet()
    }
}
