//
//  GetWhatsappAccountResponse+Mockable.swift
//  Mishkat
//
//  Created by Human on 29/03/2025.
//

extension Whatsapp_V1_GetWhatsappAccountResponse: Mockable {
    static func makeMock() -> Whatsapp_V1_GetWhatsappAccountResponse {
        var resp = Whatsapp_V1_GetWhatsappAccountResponse()
        resp.isAuthenticated = true
        resp.isReady = true
        resp.name = "Saleh AlAndalousi"
        resp.phoneNumber = "966504030201"
        resp.pairingCode = "PD1QD4"
        resp.status = "READY"
        
        return resp
    }
}
