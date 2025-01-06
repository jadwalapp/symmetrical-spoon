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
    
    func getCalendarsWithCalendarAccounts() async throws -> Calendar_V1_GetCalendarsWithCalendarAccountsResponse {
        do {
            let req = Calendar_V1_GetCalendarsWithCalendarAccountsRequest()
            
            let resp = await calendarClient.getCalendarsWithCalendarAccounts(request: req, headers: [:])
            return try resp.result.get()
        } catch {
            debugPrint("things went south running getCalendarsWithCalendarAccounts: \(error)")
            throw CalendarRepositoryError.unknown
        }
    }
    
    func createCalendar(accountId: String, name: String, color: String) async throws -> Calendar_V1_CreateCalendarResponse {
        do {
            var req = Calendar_V1_CreateCalendarRequest()
            req.calendarAccountID = accountId
            req.name = name
            req.color = color
            req.startDate = SwiftProtobuf.Google_Protobuf_Timestamp(date: Date())
            req.endDate = SwiftProtobuf.Google_Protobuf_Timestamp(date: Date().addingTimeInterval(60 * 60 * 24))
            
            let resp = await calendarClient.createCalendar(request: req, headers: [:])
            return try resp.result.get()
        } catch {
            debugPrint("things went south running getCalendars: \(error)")
            throw CalendarRepositoryError.unknown
        }
    }
    
    func createEvent(
        calendarId: String,
        title: String,
        location: String,
        isAllDay: Bool,
        startDate: Date,
        endDate: Date
    ) async throws -> Calendar_V1_CreateEventResponse {
        do {
            var req = Calendar_V1_CreateEventRequest()
            req.calendarID = calendarId
            req.title = title
            req.location = location
            req.isAllDay = isAllDay
            req.startDate = SwiftProtobuf.Google_Protobuf_Timestamp(date:  startDate)
            req.endDate = SwiftProtobuf.Google_Protobuf_Timestamp(date:  endDate)
            
            let resp = await calendarClient.createEvent(request: req, headers: [:])
            return try resp.result.get()
        } catch {
            debugPrint("things went south running createEvent: \(error)")
            throw CalendarRepositoryError.unknown
        }
    }
}
