//
//  SettingsViewModel.swift
//  Mishkat
//
//  Created by Human on 02/11/2024.
//

import Foundation
import UIKit
import SafariServices

class SettingsViewModel: ObservableObject {
    @Published var showPrayerTimesSetupWebView = false
    @Published var isPrayerTimesLoading = false
    @Published var prayerTimesSetupURL: URL? = nil
    @Published var isPrayerTimesSetupComplete: Bool {
        didSet {
            // Persist the setup status when it changes
            if isPrayerTimesSetupComplete {
                UserDefaults.standard.set(true, forKey: "isPrayerTimesSetupComplete")
            }
        }
    }
    
    private let userDefaults = UserDefaults.standard
    private static let prayerTimesSetupKey = "isPrayerTimesSetupComplete"
    
    private var calendarRepository: CalendarRepository
    
    init(calendarRepository: CalendarRepository) {
        self.calendarRepository = calendarRepository
        // Load initial setup status from UserDefaults
        self.isPrayerTimesSetupComplete = userDefaults.bool(forKey: Self.prayerTimesSetupKey)
    }
    
    /// Prepares the prayer times calendar setup URL and shows it in-app
    func setupPrayerTimesCalendar() {
        isPrayerTimesLoading = true
        
        Task {
            do {
                let schedulePrayerTimesRes = try await calendarRepository.schedulePrayerTimes()
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    let prayerTimesURL = schedulePrayerTimesRes.icalURL
                    
                    // Direct URL for webcal setup
                    let urlString = "https://falak.jadwal.app/httpj/mobile-config/webcal?url=\(prayerTimesURL)"
                    
                    if let url = URL(string: urlString) {
                        self.prayerTimesSetupURL = url
                        self.showPrayerTimesSetupWebView = true
                        self.isPrayerTimesLoading = false
                    } else {
                        debugPrint("Failed to create prayer times URL")
                        self.isPrayerTimesLoading = false
                    }
                }
            } catch {
                debugPrint("Failed to get prayer times URL")
                self.isPrayerTimesLoading = false
            }
        }
    }
    
    /// Called when the Safari view controller for prayer times is dismissed
    func prayerTimesWebViewDismissed() {
        debugPrint("prayerTimesWebViewDismissed called")
        
        // Reset URL to prevent accidental reuse - do this with a slight delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.prayerTimesSetupURL = nil
        }
    }
    
    /// Opens the iOS Settings app where profile download notice appears
    func openSettingsApp() {
        // Try to open directly to the profiles page, but this will likely just open the main Settings app
        // which is what we want, as the profile download notice appears at the top of the main Settings page
        let profileSettingsURL = URL(string: "App-prefs:root=General&path=ManagedConfigurationList")
        
        // Add a slight delay to prevent UI hanging
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if let url = profileSettingsURL, UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            } else {
                // Fallback to the main Settings page
                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsUrl)
                }
            }
        }
    }
    
    /// Reset the prayer times setup status (for testing/debugging)
    func resetPrayerTimesSetup() {
        isPrayerTimesSetupComplete = false
        userDefaults.removeObject(forKey: Self.prayerTimesSetupKey)
    }
}
