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
    
    func getCalDavAccount() async throws -> Calendar_V1_GetCalDavAccountResponse {
        do {
            let req = Calendar_V1_GetCalDavAccountRequest()
            
            let resp = await calendarClient.getCalDavAccount(request: req, headers: [:])
            return try resp.result.get()
        } catch {
            debugPrint("things went south running getCalDavaccount: \(error)")
            throw CalendarRepositoryError.unknown
        }
    }
    
    func schedulePrayerTimes() async throws -> Calendar_V1_SchedulePrayerTimesResponse {
        do {
            let req = Calendar_V1_SchedulePrayerTimesRequest()
            
            let resp = await calendarClient.schedulePrayerTimes(request: req, headers: [:])
            return try resp.result.get()
        } catch {
            debugPrint("things went south running schedulePrayerTimes: \(error)")
            throw CalendarRepositoryError.unknown
        }
    }
}
