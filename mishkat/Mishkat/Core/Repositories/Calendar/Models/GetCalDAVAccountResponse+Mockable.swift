//
//  GetCalDAVAccountResponse+Mockable.swift
//  Mishkat
//
//  Created by Human on 14/01/2025.
//

extension Calendar_V1_GetCalDAVAccountResponse: Mockable {
    static func makeMock() -> Calendar_V1_GetCalDAVAccountResponse {
        var resp = Calendar_V1_GetCalDAVAccountResponse()
        resp.username = "saleh@alandalousi.com"
        resp.password = "some long password :D"
        
        return resp
    }
}
