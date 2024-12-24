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
   
   @MainActor
   func getProfile() async {
       if case .loading = profileState { return }
       
       profileState = .loading
       
       do {
           let profile = try await profileRepository.getProfile()
           profileState = .loaded(profile)
       } catch {
           profileState = .failed(error)
       }
   }
}
