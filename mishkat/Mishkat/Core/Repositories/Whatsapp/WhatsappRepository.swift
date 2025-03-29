//
//  WhatsappRepository.swift
//  Mishkat
//
//  Created by Human on 29/03/2025.
//

import Foundation
import Connect

class WhatsappRepository {
    private let whatsappClient: Whatsapp_V1_WhatsappServiceClientInterface
    
    init(whatsappClient: Whatsapp_V1_WhatsappServiceClientInterface) {
        self.whatsappClient = whatsappClient
    }
    
    func connectWhatsappAccount(mobile: String) async throws -> Whatsapp_V1_ConnectWhatsappAccountResponse {
        do {
            var req = Whatsapp_V1_ConnectWhatsappAccountRequest()
            req.mobile = mobile
            
            let resp = await whatsappClient.connectWhatsappAccount(request: req, headers: [:])
            return try resp.result.get()
        } catch {
            debugPrint("things went south running connectWhatsappAccount: \(error)")
            throw WhatsappRepositoryError.unknown
        }
    }
    
    func disconnectWhatsappAccount() async throws -> Whatsapp_V1_DisconnectWhatsappAccountResponse {
        do {
            let req = Whatsapp_V1_DisconnectWhatsappAccountRequest()
            
            let resp = await whatsappClient.disconnectWhatsappAccount(request: req, headers: [:])
            return try resp.result.get()
        } catch {
            debugPrint("things went south running disconnectWhatsappAccount: \(error)")
            throw WhatsappRepositoryError.unknown
        }
    }
    
    func getWhatsappAccount() async throws -> Whatsapp_V1_GetWhatsappAccountResponse {
        do {
            let req = Whatsapp_V1_GetWhatsappAccountRequest()
            
            let resp = await whatsappClient.getWhatsappAccount(request: req, headers: [:])
            return try resp.result.get()
        } catch let error as ConnectError where error.code == .notFound {
            throw WhatsappRepositoryError.notFound
        } catch {
            debugPrint("things went south running getWhatsappAccount: \(error)")
            throw WhatsappRepositoryError.unknown
        }
    }
}
