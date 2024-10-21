//
//  AuthRepository.swift
//  Mishkat
//
//  Created by Human on 20/10/2024.
//

import Foundation

class AuthRepository {
    private let authClient: Auth_V1_AuthServiceClientInterface
    
    init(authClient: Auth_V1_AuthServiceClientInterface) {
        self.authClient = authClient
    }
    
    func initiateEmail(email: String) async throws -> Auth_V1_InitiateEmailResponse {
        do {
            var req = Auth_V1_InitiateEmailRequest()
            req.email = email
            
            let resp = await authClient.initiateEmail(request: req, headers: [:])
            return try resp.result.get()
        } catch {
            debugPrint("things went south running initiateEmail: \(error)")
            throw AuthRepositoryError.unknown
        }
    }
    
    func completeEmail(token: String) async throws -> Auth_V1_CompleteEmailResponse {
        do {
            var req = Auth_V1_CompleteEmailRequest()
            req.token = token
            
            let resp = await authClient.completeEmail(request: req, headers: [:])
            return try resp.result.get()
        } catch {
            debugPrint("things went south running completeEmail: \(error)")
            throw AuthRepositoryError.unknown
        }
    }
    
    func useGoogle(googleToken: String) async throws -> Auth_V1_UseGoogleResponse {
        do {
            var req = Auth_V1_UseGoogleRequest()
            req.googleToken = googleToken
            
            let resp = await authClient.useGoogle(request: req, headers: [:])
            return try resp.result.get()
        } catch {
            debugPrint("things went south running useGoogle: \(error)")
            throw AuthRepositoryError.unknown
        }
    }
}
