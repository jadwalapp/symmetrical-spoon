//
//  ContentView.swift
//  Mishkat
//
//  Created by Human on 20/10/2024.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    @StateObject private var settingsViewModel: SettingsViewModel
    @StateObject private var profileViewModel: ProfileViewModel
    @StateObject private var calendarViewModel: CalendarViewModel
    init() {
        _settingsViewModel = StateObject(wrappedValue: SettingsViewModel())
        _profileViewModel = StateObject(wrappedValue: ProfileViewModel(profileRepository: DependencyContainer.shared.profileRepository, calendarRepository: DependencyContainer.shared.calendarRepository))
        _calendarViewModel = StateObject(wrappedValue: CalendarViewModel(calendarRepository: DependencyContainer.shared.calendarRepository))
    }
    
    var body: some View {
        Group {
            if authViewModel.isAuthenticated {
                MainAppView()
                    .environmentObject(settingsViewModel)
                    .environmentObject(profileViewModel)
                    .environmentObject(calendarViewModel)
            } else {
                AuthView()
            }
        }
    }
}

#Preview {
    ContentView()
}
