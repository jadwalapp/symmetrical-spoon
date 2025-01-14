//
//  ClaendarRepository.swift
//  Mishkat
//
//  Created by Human on 04/01/2025.
//

import Foundation
import SwiftProtobuf

class CalendarRepository {
    private let calendarClient: Calendar_V1_CalendarServiceClientInterface
    
    init(calendarClient: Calendar_V1_CalendarServiceClientInterface) {
        self.calendarClient = calendarClient
    }
    
    func getCalDavaccount() async throws -> Calendar_V1_GetCalDAVAccountResponse {
        do {
            let req = Calendar_V1_GetCalDAVAccountRequest()
            
            let resp = await calendarClient.getCalDavaccount(request: req, headers: [:])
            return try resp.result.get()
        } catch {
            debugPrint("things went south running getCalDavaccount: \(error)")
            throw CalendarRepositoryError.unknown
        }
    }
}
