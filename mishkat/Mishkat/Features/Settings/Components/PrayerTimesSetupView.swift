//
//  PrayerTimesSetupView.swift
//  Mishkat
//
//  Created by Human on 01/05/2025.
//

import SwiftUI
import PostHog

struct PrayerTimesSetupView: View {
    @EnvironmentObject var settingsViewModel: SettingsViewModel
    @State private var showSetupInstructionsSheet = false
    @State private var isButtonDisabled = false // Prevent multiple taps
    @State private var showResetConfirmation = false
    
    var body: some View {
        Button {
            PostHogSDK.shared.capture("prayer_times_setup__schedule_prayer_times_clicked")
            
            // Disable the button to prevent multiple taps
            isButtonDisabled = true
            
            // Provide haptic feedback
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            
            if settingsViewModel.isPrayerTimesSetupComplete {
                // Just show a confirmation or open settings for already-setup calendar
                settingsViewModel.openSettingsApp()
                
                // Re-enable button after a delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isButtonDisabled = false
                }
            } else {
                // Small delay to prevent UI hanging when showing the sheet
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    showSetupInstructionsSheet = true
                    
                    // Re-enable button after sheet is presented
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        isButtonDisabled = false
                    }
                }
            }
        } label: {
            HStack {
                Image(systemName: settingsViewModel.isPrayerTimesSetupComplete ? "checkmark.circle.fill" : "moon.stars.fill")
                    .font(.title3)
                    .foregroundStyle(settingsViewModel.isPrayerTimesSetupComplete ? .green : Color.accentColor)
                VStack(alignment: .leading, spacing: 4) {
                    Text(settingsViewModel.isPrayerTimesSetupComplete ? "Prayer Times Connected" : "Prayer Times Calendar")
                        .font(.headline)
                    Text(settingsViewModel.isPrayerTimesSetupComplete ? "Tap to open Calendar settings" : "Get prayer time reminders")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                
                if settingsViewModel.isPrayerTimesLoading {
                    ProgressView()
                        .tint(Color.accentColor)
                } else {
                    Image(systemName: "chevron.right")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 8)
            .opacity(isButtonDisabled ? 0.7 : 1.0) // Visual feedback when disabled
        }
        .buttonStyle(.plain)
        .disabled(isButtonDisabled)
        .contextMenu {
            // Long-press menu for resetting the status
            Button(role: .destructive) {
                PostHogSDK.shared.capture("schedule_prayer_times_reset_button_clicked")
                showResetConfirmation = true
            } label: {
                Label("Reset Setup Status", systemImage: "arrow.triangle.2.circlepath")
            }
        }
        .alert("Reset Prayer Times Setup", isPresented: $showResetConfirmation) {
            Button("Reset", role: .destructive) {
                PostHogSDK.shared.capture("schedule_prayer_times_reset_button_confirmation_clicked")
                settingsViewModel.resetPrayerTimesSetup()
            }
            Button("Cancel", role: .cancel) {
                PostHogSDK.shared.capture("schedule_prayer_times_reset_button_cancel_clicked")
            }
        } message: {
            Text("This will reset the prayer times calendar setup status, allowing you to set it up again. Note that this doesn't remove the calendar subscription - it only resets the app's knowledge of whether it was set up.")
        }
        .fullScreenCover(isPresented: $showSetupInstructionsSheet) {
            PrayerTimesSetupInstructionsView()
                .environmentObject(settingsViewModel)
        }
    }
}

#Preview("Not Setup") {
    List {
        Section {
            PrayerTimesSetupView()
        }
    }
    .environmentObject({
        let vm = SettingsViewModel(calendarRepository: DependencyContainer.shared.calendarRepository)
        vm.isPrayerTimesSetupComplete = false
        return vm
    }())
}

#Preview("Setup Complete") {
    List {
        Section {
            PrayerTimesSetupView()
        }
    }
    .environmentObject({
        let vm = SettingsViewModel(calendarRepository: DependencyContainer.shared.calendarRepository)
        vm.isPrayerTimesSetupComplete = true
        return vm
    }())
} 
