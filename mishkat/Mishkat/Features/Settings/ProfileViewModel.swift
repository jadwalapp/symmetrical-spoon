//
//  ProfileViewModel.swift
//  Mishkat
//
//  Created by Human on 24/12/2024.
//

import Foundation

class ProfileViewModel: ObservableObject {
   @Published private(set) var profileState: AsyncValue<Profile_V1_GetProfileResponse> = .idle
   
   private let profileRepository: ProfileRepository
   
   init(profileRepository: ProfileRepository) {
       self.profileRepository = profileRepository
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
}
