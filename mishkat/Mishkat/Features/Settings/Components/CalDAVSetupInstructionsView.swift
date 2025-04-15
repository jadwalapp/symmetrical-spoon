//
//  CalDAVSetupInstructionsView.swift
//  Mishkat
//
//  Created by Human on 01/04/2025.
//

import SwiftUI
import SafariServices

struct CalDAVSetupInstructionsView: View {
    @EnvironmentObject var profileViewModel: ProfileViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var currentStep = 1
    @State private var countdown = 10
    @State private var isCheckingStatus = false
    @State private var timer: Timer? = nil
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    InstructionsHeaderView()
                    
                    StepProgressView(currentStep: currentStep)
                    
                    stepContent
                }
                .padding()
            }
            .navigationTitle("Easy CalDAV Setup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $profileViewModel.showCalDavSetupWebView, onDismiss: {
                debugPrint("Safari view dismissed, moving to step 2")
                handleWebViewDismissal()
            }) {
                if let url = profileViewModel.caldavSetupURL {
                    SafariViewWrapper(url: url)
                }
            }
            .onChange(of: profileViewModel.isDeviceCalDavAccountDetected) { detected in
                if detected {
                    stopCountdownTimer()
                    debugPrint("CalDAV account detected, preparing to dismiss")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        dismiss()
                    }
                }
            }
            .onChange(of: profileViewModel.calDavAccountState) { state in
                if case .loading = state {
                    isCheckingStatus = true
                } else {
                    isCheckingStatus = false
                }
            }
        }
        .onAppear {
            debugPrint("CalDAVSetupInstructionsView appeared, setting step to 1")
            currentStep = 1
            profileViewModel.showCalDavSetupInstructions = false
        }
    }
    
    private var stepContent: some View {
        Group {
            if currentStep == 1 {
                DownloadStepView(onDownload: {
                    debugPrint("Beginning download")
                    profileViewModel.initiateEasyCalDavSetup()
                })
            } else if currentStep == 2 {
                InstallStepView(onOpenSettings: {
                    debugPrint("Opening settings, will move to step 3")
                    profileViewModel.openSettingsApp()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        currentStep = 3
                    }
                })
            } else if currentStep == 3 {
                CompleteStepView(
                    isDetected: profileViewModel.isDeviceCalDavAccountDetected,
                    isChecking: isCheckingStatus,
                    countdown: countdown,
                    onCheckNow: { 
                        debugPrint("Manual check initiated")
                        checkCalDAVStatus() 
                    },
                    onOpenSettings: { profileViewModel.openSettingsApp() },
                    onDone: { dismiss() }
                )
                .onAppear { 
                    debugPrint("Step 3 appeared, starting timer")
                    startTimerIfNeeded() 
                }
                .onDisappear { stopCountdownTimer() }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func handleWebViewDismissal() {
        // Update the step immediately
        currentStep = 2
        
        // Call the webViewDismissed method which will check for the status
        profileViewModel.webViewDismissed()
        
        // Start a timer to ensure we move to step 3
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            if currentStep == 2 {
                debugPrint("Auto-advancing to step 3 after timeout")
                currentStep = 3
            }
        }
        
        // Automatically open Settings app where the profile download appears at the top
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            profileViewModel.openSettingsApp()
        }
    }
    
    private func checkCalDAVStatus() {
        Task {
            debugPrint("Checking CalDAV status")
            await profileViewModel.checkDeviceCalDavAccountStatus()
            // isCheckingStatus will be updated by onChange observer
            countdown = 10
            startCountdownTimer()
        }
    }
    
    private func startTimerIfNeeded() {
        if currentStep == 3 && !profileViewModel.isDeviceCalDavAccountDetected {
            debugPrint("Starting countdown timer in step 3")
            startCountdownTimer()
        }
    }
    
    private func startCountdownTimer() {
        stopCountdownTimer()
        countdown = 10
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if countdown > 0 {
                countdown -= 1
            } else {
                debugPrint("Countdown reached zero, checking status")
                checkCalDAVStatus()
            }
        }
    }
    
    private func stopCountdownTimer() {
        timer?.invalidate()
        timer = nil
    }
}

// MARK: - Sub-Components

struct InstructionsHeaderView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Set Up Your Calendar")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("We'll guide you through connecting your CalDAV account in just a few steps.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

struct StepProgressView: View {
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

struct DownloadStepView: View {
    let onDownload: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            StepHeading(number: 1, title: "Download Configuration")
            
            Text("Jadwal will download a configuration profile that automatically sets up your CalDAV account on this device.")
                .foregroundStyle(.secondary)
            
            Image(systemName: "arrow.down.doc.fill")
                .font(.system(size: 60))
                .foregroundStyle(Color.accentColor)
                .frame(maxWidth: .infinity)
                .padding()
            
            Text("This is a secure process that configures your device to connect with our calendar server.")
                .foregroundStyle(.secondary)
                .font(.callout)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
            
            Button(action: onDownload) {
                Text("Begin Download")
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

struct InstallStepView: View {
    let onOpenSettings: () -> Void
    @EnvironmentObject var profileViewModel: ProfileViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            StepHeading(number: 2, title: "Install Profile")
            
            if case .loading = profileViewModel.calDavAccountState {
                VStack(spacing: 16) {
                    HStack {
                        ProgressView()
                            .padding(.trailing, 8)
                        Text("Checking for CalDAV profile...")
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                    
                    InstallStepsListView()
                }
            } else {
                Text("The configuration profile has been downloaded. Now you need to install it in your device settings.")
                    .foregroundStyle(.secondary)
                
                InstallStepsListView()
            }
            
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

struct InstallStepsListView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ProfileInstallStep(number: 1, text: "Open Settings app")
            ProfileInstallStep(number: 2, text: "Look for 'Profile Downloaded' near the top")
            ProfileInstallStep(number: 3, text: "Tap to install the profile")
            ProfileInstallStep(number: 4, text: "Follow the prompts and enter your passcode if required")
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct CompleteStepView: View {
    let isDetected: Bool
    let isChecking: Bool
    let countdown: Int
    let onCheckNow: () -> Void
    let onOpenSettings: () -> Void
    let onDone: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            StepHeading(number: 3, title: "Complete Setup")
            
            if isDetected {
                successView
            } else {
                waitingView
            }
        }
    }
    
    private var successView: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.largeTitle)
                
                VStack(alignment: .leading) {
                    Text("CalDAV Account Detected!")
                        .font(.headline)
                        .foregroundStyle(.green)
                    
                    Text("Your calendars are now connected to Jadwal")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.green.opacity(0.1))
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
    
    private var waitingView: some View {
        VStack(spacing: 16) {
            Text("Waiting for the profile installation to complete...")
                .foregroundStyle(.secondary)
            
            statusRowView
            
            actionButtonsView
        }
    }
    
    private var statusRowView: some View {
        VStack(spacing: 12) {
            HStack {
                if isChecking {
                    ProgressView()
                        .padding(.trailing, 8)
                    Text("Checking for CalDAV account...")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    Image(systemName: "timer")
                        .foregroundStyle(Color.accentColor)
                        .padding(.trailing, 8)
                    Text("Checking again in \(countdown) seconds")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            
            // Enhanced visual feedback when checking
            if isChecking {
                HStack(spacing: 4) {
                    Text("Checking iOS Calendar app for CalDAV account")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                }
                .padding(.horizontal, 8)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(isChecking ? Color.blue.opacity(0.1) : Color(.systemGray6))
        .cornerRadius(8)
        .animation(.easeInOut(duration: 0.3), value: isChecking)
    }
    
    private var actionButtonsView: some View {
        HStack {
            Button(action: onCheckNow) {
                Label("Check Now", systemImage: "arrow.clockwise")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor.opacity(0.1))
                    .foregroundStyle(Color.accentColor)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .disabled(isChecking)
            .opacity(isChecking ? 0.6 : 1.0)
            
            Button(action: onOpenSettings) {
                Label("Open Settings", systemImage: "gear")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
    }
}

// MARK: - Supporting Views

struct StepHeading: View {
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

struct ProfileInstallStep: View {
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

//MARK: - Preview

#Preview {
    CalDAVSetupInstructionsView()
        .environmentObject(ProfileViewModel(
            profileRepository: DependencyContainer.shared.profileRepository,
            calendarRepository: DependencyContainer.shared.calendarRepository,
            whatsappRepository: DependencyContainer.shared.whatsappRepository
        ))
}

#Preview("Download Step") {
    DownloadStepView(onDownload: {})
        .padding()
}

#Preview("Install Step") {
    InstallStepView(onOpenSettings: {})
        .padding()
}

#Preview("Complete Success") {
    CompleteStepView(
        isDetected: true,
        isChecking: false,
        countdown: 10,
        onCheckNow: {},
        onOpenSettings: {},
        onDone: {}
    )
    .padding()
} 
