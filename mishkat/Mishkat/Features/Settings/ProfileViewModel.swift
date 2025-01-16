//
//  ProfileViewModel.swift
//  Mishkat
//
//  Created by Human on 24/12/2024.
//

import Foundation

class ProfileViewModel: ObservableObject {
    @Published private(set) var profileState: AsyncValue<Profile_V1_GetProfileResponse> = .idle
    @Published private(set) var calDavAccountState: AsyncValue<Calendar_V1_GetCalDavAccountResponse> = .idle
    
    private let profileRepository: ProfileRepository
    private let calendarRepository: CalendarRepository
    
    init(profileRepository: ProfileRepository, calendarRepository: CalendarRepository) {
        self.profileRepository = profileRepository
        self.calendarRepository = calendarRepository
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
        if case .loading = self.profileState { return }
        
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
}
