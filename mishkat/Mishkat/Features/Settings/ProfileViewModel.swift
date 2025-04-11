//
//  ProfileViewModel.swift
//  Mishkat
//
//  Created by Human on 24/12/2024.
//

import Foundation
import EventKit
import UIKit
import SafariServices

class ProfileViewModel: ObservableObject {
    @Published private(set) var profileState: AsyncValue<Profile_V1_GetProfileResponse> = .idle
    @Published private(set) var calDavAccountState: AsyncValue<Calendar_V1_GetCalDavAccountResponse> = .idle
    @Published private(set) var whatsappAccountState: AsyncValue<Whatsapp_V1_GetWhatsappAccountResponse> = .idle
    @Published var showWhatsappSheet = false {
        didSet {
            if showWhatsappSheet {
                // Only disconnect if we're not in WAITING_FOR_PAIRING state
                Task {
                    let response = try? await whatsappRepository.getWhatsappAccount()
                    if response?.status != "WAITING_FOR_PAIRING" {
                        _ = try? await whatsappRepository.disconnectWhatsappAccount()
                    }
                }
            }
        }
    }
    
    // CalDAV account detection
    @Published var isDeviceCalDavAccountDetected: Bool = false
    @Published var showCalDavSetupInstructions: Bool = false
    @Published var calDavSetupInstructionsMessage: String = ""
    private let eventStore = EKEventStore()
    
    @Published var caldavSetupURL: URL? = nil
    @Published var showCalDavSetupWebView = false
    @Published var showSetupInstructionsSheet = false
    
    private let profileRepository: ProfileRepository
    private let calendarRepository: CalendarRepository
    private let whatsappRepository: WhatsappRepository
    private let authRepository: AuthRepository
    
    init(profileRepository: ProfileRepository, calendarRepository: CalendarRepository, whatsappRepository: WhatsappRepository, authRepository: AuthRepository = DependencyContainer.shared.authRepository) {
        self.profileRepository = profileRepository
        self.calendarRepository = calendarRepository
        self.whatsappRepository = whatsappRepository
        self.authRepository = authRepository
        
        // Check for CalDAV account on app start
        Task {
            await checkDeviceCalDavAccountStatus()
        }
        
        // Start listening for app state changes
        startListeningForAppState()
    }
    
    func getProfile() {
        if case .loading = self.profileState { return }
        
        Task {
            await MainActor.run {
                self.profileState = .loading
            }
            
            do {
                let profile = try await profileRepository.getProfile()
                await MainActor.run {
                    self.profileState = .loaded(profile)
                }
            } catch {
                await MainActor.run {
                    self.profileState = .failed(error)
                }
            }
        }
    }
    
    func getCalDavAccount() {
        if case .loading = self.calDavAccountState { return }
        
        Task {
            await MainActor.run {
                self.calDavAccountState = .loading
            }
            
            do {
                let calDavAccountResp = try await calendarRepository.getCalDavAccount()
                await MainActor.run {
                    self.calDavAccountState = .loaded(calDavAccountResp)
                }
            } catch {
                await MainActor.run {
                    self.calDavAccountState = .failed(error)
                }
            }
        }
    }
    
    func getWhatsappAccount() {
        if case .loading = self.whatsappAccountState { return }
        
        Task {
            await MainActor.run {
                self.whatsappAccountState = .loading
            }
            
            do {
                let whatsappAccount = try await whatsappRepository.getWhatsappAccount()
                await MainActor.run {
                    self.whatsappAccountState = .loaded(whatsappAccount)
                }
            } catch WhatsappRepositoryError.notFound {
                await MainActor.run {
                    var emptyResponse = Whatsapp_V1_GetWhatsappAccountResponse()
                    emptyResponse.isReady = false
                    emptyResponse.isAuthenticated = false
                    self.whatsappAccountState = .loaded(emptyResponse)
                }
            } catch {
                await MainActor.run {
                    self.whatsappAccountState = .failed(error)
                }
            }
        }
    }
    
    func disconnectWhatsapp() {
        Task {
            do {
                _ = try await whatsappRepository.disconnectWhatsappAccount()
                await MainActor.run {
                    self.whatsappAccountState = .idle
                    self.getWhatsappAccount()
                }
            } catch {
                debugPrint("Failed to disconnect WhatsApp: \(error)")
            }
        }
    }
    
    // MARK: - CalDAV Account Setup
    
    /// Shows instructions and begins the CalDAV setup process
    func beginCalDavSetup() {
        showSetupInstructionsSheet = true
    }
    
    /// Initiates the easy CalDAV setup process by generating a magic token,
    /// constructing the URL with the token, and opening it in Safari.
    func initiateEasyCalDavSetup() {
        Task {
            do {
                // Generate a magic token for CalDAV
                let response = try await authRepository.generateMagicToken(type: .caldav)
                let magicToken = response.magicToken
                
                // Construct the URL for downloading the mobileconfig file
                let urlString = "https://falak.jadwal.app/httpj/mobile-config/caldav?s=\(magicToken)"
                
                if let url = URL(string: urlString) {
                    // Store URL for SFSafariViewController to use
                    await MainActor.run {
                        self.caldavSetupURL = url
                        self.showCalDavSetupWebView = true
                    }
                }
            } catch {
                debugPrint("Failed to generate magic token for CalDAV setup: \(error)")
                await MainActor.run {
                    self.calDavSetupInstructionsMessage = "Failed to generate setup link. Please try again or use the manual setup method."
                    self.showCalDavSetupInstructions = true
                }
            }
        }
    }
    
    /// Called when the Safari view controller is dismissed
    func webViewDismissed() {
        debugPrint("webViewDismissed called")
        
        // Reset URL to prevent accidental reuse
        caldavSetupURL = nil
        
        // Make sure we update the UI state to loading
        Task { @MainActor in
            self.calDavAccountState = .loading
        }
        
        // Check for CalDAV account status after a delay to give the user time to install the profile
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            debugPrint("Running delayed CalDAV check after web view dismissed")
            Task {
                await self.checkDeviceCalDavAccountStatus()
            }
        }
    }
    
    /// Opens the iOS Settings app to the main page where profile downloads appear
    func openSettingsApp() {
        // Try to open directly to the profiles page, but this will likely just open the main Settings app
        // which is what we want, as the profile download notice appears at the top of the main Settings page
        let profileSettingsURL = URL(string: "App-prefs:root=General&path=ManagedConfigurationList")
        
        if let url = profileSettingsURL, UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        } else {
            // Fallback to the main Settings page
            if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsUrl)
            }
        }
    }
    
    /// Checks if the CalDAV account is already set up on the device
    @MainActor
    func checkDeviceCalDavAccountStatus() async {
        debugPrint("Starting checkDeviceCalDavAccountStatus")
        
        // Set the CalDAV account state to loading at the start of the check
        if calDavAccountState != .loading {
            calDavAccountState = .loading
        }
        
        // First ask for calendar permission
        do {
            let granted: Bool
            
            if #available(iOS 17.0, *) {
                granted = try await eventStore.requestFullAccessToEvents()
            } else {
                // Fall back to the completion handler API for iOS < 17
                granted = await withCheckedContinuation { continuation in
                    eventStore.requestAccess(to: .event) { granted, _ in
                        continuation.resume(returning: granted)
                    }
                }
            }
            
            if granted {
                debugPrint("Calendar access granted, checking for CalDAV account")
                await getCalDavAccountAndCheckStatus()
            } else {
                debugPrint("Calendar access denied")
                self.isDeviceCalDavAccountDetected = false
                calDavAccountState = .failed(ProfileRepositoryError.calendarAccessDenied)
            }
        } catch {
            debugPrint("Error accessing event store: \(error)")
            self.isDeviceCalDavAccountDetected = false
            calDavAccountState = .failed(error)
        }
    }
    
    /// Helper method to get account info and check status in one go
    @MainActor
    private func getCalDavAccountAndCheckStatus() async {
        do {
            debugPrint("Fetching CalDAV account info from server")
            let calDavAccountResp = try await calendarRepository.getCalDavAccount()
            calDavAccountState = .loaded(calDavAccountResp)
            
            // Now that we have the account info, check if it's on the device
            let sources = eventStore.sources
            let accountExists = sources.contains { source in
                let matches = source.sourceType == .calDAV && 
                    (source.title.lowercased().contains("jadwal") || 
                     source.title.lowercased().contains(calDavAccountResp.username.lowercased()))
                
                if matches {
                    debugPrint("Found matching CalDAV account: \(source.title)")
                }
                return matches
            }
            
            debugPrint("Sources checked: \(sources.count), CalDAV account exists: \(accountExists)")
            self.isDeviceCalDavAccountDetected = accountExists
        } catch {
            debugPrint("Error getting CalDAV account: \(error)")
            calDavAccountState = .failed(error)
            self.isDeviceCalDavAccountDetected = false
        }
    }
    
    /// Starts observing app state changes to refresh CalDAV status when app becomes active
    private func startListeningForAppState() {
        NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self = self else { return }
            Task {
                await self.checkDeviceCalDavAccountStatus()
            }
        }
    }
}
