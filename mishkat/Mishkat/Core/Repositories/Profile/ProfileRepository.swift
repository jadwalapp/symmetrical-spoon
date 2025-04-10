//
//  ProfileRepository.swift
//  Mishkat
//
//  Created by Human on 22/12/2024.
//

import Foundation

class ProfileRepository {
    private let profileClient: Profile_V1_ProfileServiceClientInterface
    
    init(profileClient: Profile_V1_ProfileServiceClientInterface) {
        self.profileClient = profileClient
    }
    
    func getProfile() async throws -> Profile_V1_GetProfileResponse {
        do {
            let req = Profile_V1_GetProfileRequest()
            
            let resp = await profileClient.getProfile(request: req, headers: [:])
            return try resp.result.get()
        } catch {
            debugPrint("things went south running getProfile: \(error)")
            throw ProfileRepositoryError.unknown
        }
    }
    
    func addDevice(deviceToken: String) async throws -> Profile_V1_AddDeviceResponse {
        do {
            var req = Profile_V1_AddDeviceRequest()
            req.deviceToken = deviceToken
            
            let resp = await profileClient.addDevice(request: req, headers: [:])
            return try resp.result.get()
        } catch {
            debugPrint("things went south running addDevice: \(error)")
            throw ProfileRepositoryError.unknown
        }
    }
}
