//
//  AuthRepository.swift
//  Mishkat
//
//  Created by Human on 20/10/2024.
//

import Foundation

class AuthRepository {
    private let authClient: Auth_AuthClientProtocol
    
    init(authClient: Auth_AuthClientProtocol) {
        self.authClient = authClient
    }
    
    func initiateEmail(email: String) async throws -> Auth_InitiateEmailResponse {
        do {
            var req = Auth_InitiateEmailRequest()
            req.email = email
            
            let resp = authClient.initiateEmail(req)
            return try await resp.response.get()
        } catch {
            debugPrint("things went south running initiateEmail: \(error)")
            throw AuthRepositoryError.unknown
        }
    }
    
    func completeEmail(token: String) async throws -> Auth_CompleteEmailResponse {
        do {
            var req = Auth_CompleteEmailRequest()
            req.token = token
            
            let resp = authClient.completeEmail(req)
            return try await resp.response.get()
        } catch {
            debugPrint("things went south running completeEmail: \(error)")
            throw AuthRepositoryError.unknown
        }
    }
    
    func useGoogle(googleToken: String) async throws -> Auth_UseGoogleResponse {
        do {
            var req = Auth_UseGoogleRequest()
            req.googleToken = googleToken
            
            let resp = authClient.useGoogle(req)
            return try await resp.response.get()
        } catch {
            debugPrint("things went south running useGoogle: \(error)")
            throw AuthRepositoryError.unknown
        }
    }
}
