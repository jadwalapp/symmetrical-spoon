//
//  CalendarAccountWithCalendars+Identifiable.swift
//  Mishkat
//
//  Created by Human on 05/01/2025.
//

extension Calendar_V1_CalendarAccountWithCalendars: Identifiable {
    public var id: String {
        self.account.id
    }
}
