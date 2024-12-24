//
//  GetProfileResponse+Mockable.swift
//  Mishkat
//
//  Created by Human on 22/12/2024.
//

extension Profile_V1_GetProfileResponse: Mockable {
    static func makeMock() -> Profile_V1_GetProfileResponse {
        var resp = Profile_V1_GetProfileResponse()
        resp.name = "Saleh AlAndalousi"
        resp.email = "saleh@jadwal.app"
        
        return resp
    }
}
