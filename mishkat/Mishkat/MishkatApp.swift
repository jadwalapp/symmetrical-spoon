//
//  MishkatApp.swift
//  Mishkat
//
//  Created by Human on 19/10/2024.
//

import SwiftUI
import PostHog

@main
struct MishkatApp: App {
    @StateObject public var authViewModel: AuthViewModel
    @UIApplicationDelegateAdaptor private var appDelegate: MishkatAppDelegate
    
    init() {
        let POSTHOG_API_KEY = "phc_E20fM1IG9toCEsc5sLuXrY6GBeBioLXyx8LSIQorf3s"
        let POSTHOG_HOST = "https://us.i.posthog.com"
        
        
        let config = PostHogConfig(apiKey: POSTHOG_API_KEY, host: POSTHOG_HOST)
        config.sessionReplay = true
        config.sessionReplayConfig.maskAllImages = false
        config.sessionReplayConfig.maskAllTextInputs = true
        config.sessionReplayConfig.screenshotMode = true
        PostHogSDK.shared.setup(config)
        
        
        PostHogSDK.shared.capture("i_guess_it_works")
        
        _authViewModel = StateObject(wrappedValue: AuthViewModel(
            authRepository: DependencyContainer.shared.authRepository,
            profileRepository: DependencyContainer.shared.profileRepository
        ))
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authViewModel)
                .onOpenURL { url in
                    handleDeepLink(url)
                }
        }
    }
    
    private func handleDeepLink(_ url: URL) {
        guard url.path == "/magic-link",
              let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
              let token = components.queryItems?.first(where: { $0.name == "token" })?.value
        else {
            print("Deep link URL is not a valid magic link: \(url)")
            return
        }
        print("Handling magic link deep link with token.")
        authViewModel.completeEmail(token: token)
    }
}
