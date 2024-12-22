//
//  SettingsViewModel.swift
//  Mishkat
//
//  Created by Human on 02/11/2024.
//

import Foundation

class SettingsViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var error: String?
    @Published var profileData: Profile_V1_GetProfileResponse?
    
    private let profileRepository: ProfileRepository
    init(profileRepository: ProfileRepository) {
        self.profileRepository = profileRepository
    }
    
    func getProfile() {
        isLoading = true
        
        Task {
            do {
                let resp = try await profileRepository.getProfile()
                await MainActor.run {
                    self.profileData = resp
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.error = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
}
