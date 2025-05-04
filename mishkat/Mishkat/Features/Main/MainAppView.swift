//
//  MainAppView.swift
//  Mishkat
//
//  Created by Human on 20/10/2024.
//

import SwiftUI
import PostHog

struct MainAppView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            CalendarView()
                .tabItem {
                    Label("Calendar", systemImage: "calendar")
                        .onTapGesture {
                            PostHogSDK.shared.capture("calendar_tab_clicked")
                        }
                }
                .tag(0)
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                        .onTapGesture {
                            PostHogSDK.shared.capture("settings_tab_clicked")
                        }
                }
                .tag(1)
        }
    }
}

#Preview {
    MainAppView()
}
