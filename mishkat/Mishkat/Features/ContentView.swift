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
        _settingsViewModel = StateObject(wrappedValue: SettingsViewModel(calendarRepository: DependencyContainer.shared.calendarRepository))
        _profileViewModel = StateObject(wrappedValue: ProfileViewModel(
            profileRepository: DependencyContainer.shared.profileRepository, 
            calendarRepository: DependencyContainer.shared.calendarRepository, 
            whatsappRepository: DependencyContainer.shared.whatsappRepository, 
            authRepository: DependencyContainer.shared.authRepository
        ))
        _calendarViewModel = StateObject(wrappedValue: CalendarViewModel())
    }
    
    var body: some View {
        Group {
            if authViewModel.isAuthenticated {
                MainAppView()
                    .environmentObject(settingsViewModel)
                    .environmentObject(profileViewModel)
                    .environmentObject(calendarViewModel)
                    .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                        // Check CalDAV status when app becomes active
                        if authViewModel.isAuthenticated {
                            Task {
                                await profileViewModel.checkDeviceCalDavAccountStatus()
                            }
                        }
                    }
            } else {
                AuthView()
            }
        }
    }
}

#Preview {
    ContentView()
}
