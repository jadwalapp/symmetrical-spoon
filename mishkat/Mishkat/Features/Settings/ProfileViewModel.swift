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
    @Published private(set) var whatsappAccountState: AsyncValue<Whatsapp_V1_GetWhatsappAccountResponse> = .idle
    @Published var showWhatsappSheet = false
    
    private let profileRepository: ProfileRepository
    private let calendarRepository: CalendarRepository
    private let whatsappRepository: WhatsappRepository
    
    init(profileRepository: ProfileRepository, calendarRepository: CalendarRepository, whatsappRepository: WhatsappRepository) {
        self.profileRepository = profileRepository
        self.calendarRepository = calendarRepository
        self.whatsappRepository = whatsappRepository
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
}
