//
//  PrayerTimesSetupInstructionsView.swift
//  Mishkat
//
//  Created by Human on 01/05/2025.
//

import SwiftUI
import SafariServices
import PostHog

struct PrayerTimesSetupInstructionsView: View {
    @EnvironmentObject var settingsViewModel: SettingsViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var currentStep = 1
    @State private var countdown = 10
    @State private var timer: Timer? = nil
    @State private var isWebViewPresented = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    PrayerTimesHeaderView()
                    
                    PrayerStepProgressView(currentStep: currentStep)
                    
                    stepContent
                }
                .padding()
            }
            .navigationTitle("Prayer Times Setup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        // Prevent double-tap issues by disabling immediate re-taps
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
                        
                        if currentStep == 3 {
                            settingsViewModel.isPrayerTimesSetupComplete = true
                        }
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            dismiss()
                        }
                    }
                }
            }
            .sheet(isPresented: $isWebViewPresented, onDismiss: {
                debugPrint("Prayer times Safari view dismissed, moving to step 2")
                handleWebViewDismissal()
            }) {
                if let url = settingsViewModel.prayerTimesSetupURL {
                    SafariViewWrapper(url: url)
                        .edgesIgnoringSafeArea(.all)
                }
            }
            .onChange(of: settingsViewModel.showPrayerTimesSetupWebView) { newValue in
                if newValue {
                    // Small delay to prevent UI hang
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        isWebViewPresented = true
                        // Reset the trigger from the ViewModel
                        settingsViewModel.showPrayerTimesSetupWebView = false
                    }
                }
            }
        }
        .onAppear {
            debugPrint("PrayerTimesSetupInstructionsView appeared, setting step to 1")
            currentStep = 1
        }
        .onDisappear {
            stopCountdownTimer()
        }
    }
    
    private var stepContent: some View {
        Group {
            if currentStep == 1 {
                PrayerDownloadStepView(onDownload: {
                    PostHogSDK.shared.capture("prayer_times_setup__download_step__download_clicked")
                    debugPrint("Beginning prayer times download")
                    // Provide haptic feedback
                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                    impactFeedback.impactOccurred()
                    
                    settingsViewModel.setupPrayerTimesCalendar()
                })
                .onAppear {
                    PostHogSDK.shared.capture("prayer_times_setup__download_step__shown")
                }
            } else if currentStep == 2 {
                PrayerInstallStepView(onOpenSettings: {
                    PostHogSDK.shared.capture("prayer_times_setup__install_step__open_settings_clicked")
                    debugPrint("Opening settings, will move to step 3")
                    // Provide haptic feedback
                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                    impactFeedback.impactOccurred()
                    
                    settingsViewModel.openSettingsApp()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        currentStep = 3
                    }
                })
                .onAppear {
                    PostHogSDK.shared.capture("prayer_times_setup__install_step_shown")
                }
            } else if currentStep == 3 {
                PrayerCompleteStepView(
                    onOpenSettings: {
                        PostHogSDK.shared.capture("prayer_times_setup__complete_step__open_settings_clicked")
                        // Provide haptic feedback
                        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                        impactFeedback.impactOccurred()
                        
                        settingsViewModel.openSettingsApp() 
                    },
                    onDone: {
                        PostHogSDK.shared.capture("prayer_times_setup__complete_step__done_clicked")
                        
                        // Provide success haptic feedback
                        let notificationFeedback = UINotificationFeedbackGenerator()
                        notificationFeedback.notificationOccurred(.success)
                        
                        // Mark setup as complete when Done is tapped
                        settingsViewModel.isPrayerTimesSetupComplete = true
                        
                        // Slight delay to prevent UI hang
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            dismiss() 
                        }
                    }
                ).onAppear {
                    PostHogSDK.shared.capture("prayer_times_setup__complete_step_shown")
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func handleWebViewDismissal() {
        // Update the step immediately
        currentStep = 2
        
        // Call the webViewDismissed method
        settingsViewModel.prayerTimesWebViewDismissed()
        
        // Start a timer to ensure we move to step 3
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            if currentStep == 2 {
                debugPrint("Auto-advancing to step 3 after timeout")
                currentStep = 3
                // Mark as complete when we reach step 3
                settingsViewModel.isPrayerTimesSetupComplete = true
            }
        }
        
        // Automatically open Settings app where the profile download appears at the top
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            settingsViewModel.openSettingsApp()
        }
    }
    
    private func stopCountdownTimer() {
        timer?.invalidate()
        timer = nil
    }
}

// MARK: - Sub-Components

struct PrayerTimesHeaderView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Prayer Times Calendar")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Set up automatic prayer time notifications on your device.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

struct PrayerStepProgressView: View {
    let currentStep: Int
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(1...3, id: \.self) { step in
                Circle()
                    .frame(width: 20, height: 20)
                    .foregroundStyle(step == currentStep ? Color.accentColor : .gray.opacity(0.3))
                
                if step < 3 {
                    Rectangle()
                        .frame(height: 2)
                        .foregroundStyle(.gray.opacity(0.3))
                }
            }
        }
        .padding(.vertical)
    }
}

struct PrayerDownloadStepView: View {
    let onDownload: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            PrayerStepHeading(number: 1, title: "Download Prayer Calendar")
            
            Text("Jadwal will download a configuration profile that adds prayer times to your device calendar.")
                .foregroundStyle(.secondary)
            
            Image(systemName: "moon.stars.fill")
                .font(.system(size: 60))
                .foregroundStyle(Color.accentColor)
                .frame(maxWidth: .infinity)
                .padding()
            
            Text("You'll receive automatic notifications for all five daily prayers based on your location.")
                .foregroundStyle(.secondary)
                .font(.callout)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
            
            Button(action: onDownload) {
                Text("Begin Setup")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .font(.headline)
            }
            .padding(.top)
        }
    }
}

struct PrayerInstallStepView: View {
    let onOpenSettings: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            PrayerStepHeading(number: 2, title: "Install Profile")
            
            Text("The prayer times calendar configuration profile has been downloaded. Now you need to install it in your device settings.")
                .foregroundStyle(.secondary)
            
            PrayerInstallStepsListView()
            
            Button(action: onOpenSettings) {
                Label("Open Settings", systemImage: "gear")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .font(.headline)
            }
            .padding(.top)
        }
    }
}

struct PrayerInstallStepsListView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            PrayerInstallStep(number: 1, text: "Open Settings app")
            PrayerInstallStep(number: 2, text: "Look for 'Profile Downloaded' near the top")
            PrayerInstallStep(number: 3, text: "Tap to install the profile")
            PrayerInstallStep(number: 4, text: "Follow the prompts and enter your passcode if required")
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct PrayerCompleteStepView: View {
    let onOpenSettings: () -> Void
    let onDone: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            PrayerStepHeading(number: 3, title: "Complete Setup")
            
            VStack(spacing: 16) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.largeTitle)
                    
                    VStack(alignment: .leading) {
                        Text("Prayer Times Calendar Added!")
                            .font(.headline)
                            .foregroundStyle(.green)
                        
                        Text("You will now receive notifications for prayer times")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.green.opacity(0.1))
                .cornerRadius(8)
                
                VStack(alignment: .leading, spacing: 16) {
                    Text("What's next?")
                        .font(.headline)
                    
                    PrayerFeatureRow(
                        icon: "bell.badge.fill",
                        title: "Automatic Notifications",
                        description: "You'll receive alerts before each prayer time"
                    )
                    
                    PrayerFeatureRow(
                        icon: "calendar",
                        title: "Calendar Integration",
                        description: "Prayer times appear in your iOS Calendar app"
                    )
                    
                    PrayerFeatureRow(
                        icon: "location.fill",
                        title: "Location-based",
                        description: "Times adjust based on your current location"
                    )
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
                
                Button(action: onDone) {
                    Text("Done")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.green)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .font(.headline)
                }
                .padding(.top)
            }
        }
    }
}

// MARK: - Supporting Views

struct PrayerStepHeading: View {
    let number: Int
    let title: String
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.accentColor)
                    .frame(width: 30, height: 30)
                
                Text("\(number)")
                    .foregroundStyle(.white)
                    .font(.headline)
            }
            
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
        }
    }
}

struct PrayerInstallStep: View {
    let number: Int
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number).")
                .font(.headline)
                .foregroundStyle(.primary)
                .frame(width: 25, alignment: .leading)
            
            Text(text)
                .foregroundStyle(.primary)
        }
    }
}

struct PrayerFeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(Color.accentColor)
                .font(.title3)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

//MARK: - Preview

#Preview {
    PrayerTimesSetupInstructionsView()
        .environmentObject(SettingsViewModel(
            calendarRepository: DependencyContainer.shared.calendarRepository
        ))
}

#Preview("Download Step") {
    PrayerDownloadStepView(onDownload: {})
        .padding()
}

#Preview("Install Step") {
    PrayerInstallStepView(onOpenSettings: {})
        .padding()
} 
