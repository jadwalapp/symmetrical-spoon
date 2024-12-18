//
//  SettingsView.swift
//  Mishkat
//
//  Created by Human on 20/10/2024.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
        
    var body: some View {
        List {
            Section {
                HStack {
                    Circle()
                        .frame(width: 60)
                        .padding(.trailing, 16)
                    VStack(alignment: .leading) {
                        Text("Hello Yazeed!")
                            .font(.headline)
                        Text("yazeedfady@gmail.com")
                            .font(.subheadline)
                    }
                    Spacer()
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
    }
}

#Preview {
    SettingsView()
}
