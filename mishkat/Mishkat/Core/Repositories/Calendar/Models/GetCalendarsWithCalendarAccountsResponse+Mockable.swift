//
//  GetCalendarsWithCalendarAccountsResponse+Mockable.swift
//  Mishkat
//
//  Created by Human on 04/01/2025.
//

extension Calendar_V1_GetCalendarsWithCalendarAccountsResponse: Mockable {
    static func makeMock() -> Calendar_V1_GetCalendarsWithCalendarAccountsResponse {
        var resp = Calendar_V1_GetCalendarsWithCalendarAccountsResponse()
        
        var fakeAccount = Calendar_V1_CalendarAccount()
        fakeAccount.id = "fakeAccountId"
        var fakeEntry = Calendar_V1_CalendarAccountWithCalendars()
        fakeEntry.account = fakeAccount
        
        var fakeCalendar = Calendar_V1_Calendar()
        fakeCalendar.calendarAccountID = fakeAccount.id
        fakeCalendar.color = "#C35831"
        fakeCalendar.id = "fakeCalendarId"
        fakeCalendar.name = "Fake Calendar"
        fakeEntry.calendars.append(fakeCalendar)
        
        resp.calendarAccountWithCalendarsList = [
            fakeEntry,
            fakeEntry,
        ]
        
        return resp
    }
}
